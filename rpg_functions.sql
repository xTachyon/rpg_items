/* triggers */
create or replace trigger on_item_delete
  before delete on rpg_items for each row
  begin
    delete from RPG_ITEM_STATS where RPG_ITEM_STATS.ITEM_ID = :OLD.item_id;
  end;

create or replace trigger on_character_delete
  before delete on RPG_CHARACTERS for each row
  begin
    delete from RPG_ITEMS where RPG_ITEMS.OWNER_ID = :OLD.CHARACTER_ID;
  end;

/* login */
create or replace function user_login(in_username in rpg_users.username%type, in_password in rpg_users.password%type)
return rpg_users.user_id%type is
  v_user_id rpg_users.user_id%type;
  counter number;
  mesaj varchar2(100);
begin
  select USER_ID into v_user_id
  from RPG_USERS
  where in_username = USERNAME and in_password = PASSWORD;
  return v_user_id;
  exception
  when no_data_found then
    SELECT COUNT(*) INTO counter FROM RPG_USERS WHERE USERNAME = in_username;
    IF counter = 0 THEN
      mesaj   := 'Utilizatorul ' || in_username || ' nu exista.';
    ELSE
      mesaj   := 'Parola gresita pentru utilizatorul ' || in_username || '.';
    END IF;
    raise_application_error (-20001, mesaj);
end;

/* characters list */
create or replace type character_list_record is object (
  character_id int,
  character_name varchar2(20),
  character_level int,
  character_delete_timer varchar2(20)
);
/
create or replace type character_list as table of character_list_record;
/
drop type character_list;
/
create or replace procedure get_characters(in_user_id in rpg_users.USER_ID%type, out_characters out character_list) as
  begin
    select character_list_record(CHARACTER_ID, name, floor(CHARACTER_LEVEL), trim(nvl(to_char(ceil(trunc(DELETED_AT + 3) - sysdate)),'inf')))
      bulk collect into out_characters
    from RPG_CHARACTERS c join RPG_USERS u on u.USER_ID = c.USER_ID
    where u.USER_ID = in_user_id;
  end;

create or replace procedure delete_character(in_character_id in rpg_characters.CHARACTER_ID%type) as
  cursor character_row is select * from RPG_CHARACTERS where in_character_id = CHARACTER_ID
    for update of DELETED_AT nowait ;
begin
  for row in character_row loop
    if(row.DELETED_AT is not null) then
      raise_application_error(-20002, 'Caracterul deja este pe lista pentru a fi sters.');
    else
      update RPG_CHARACTERS set DELETED_AT = sysdate where CURRENT OF character_row;
    end if;
  end loop;
end;

  create or replace procedure restore_character(in_character_id in rpg_characters.CHARACTER_ID%type) as
  cursor character_row is select * from RPG_CHARACTERS where in_character_id = CHARACTER_ID
    for update of DELETED_AT nowait ;
begin
  for row in character_row loop
    if(row.DELETED_AT is null) then
      raise_application_error(-20003, 'Caracterul nu este pe lista pentru a fi sters.');
    else
      update RPG_CHARACTERS set DELETED_AT = null where CURRENT OF character_row;
    end if;
  end loop;
end;

create or replace procedure delete_characters_job as
  begin
    delete from RPG_CHARACTERS where DELETED_AT is not null and ceil(trunc(DELETED_AT + 3) - sysdate) <= 0;
  end;

BEGIN
 DBMS_SCHEDULER.CREATE_JOB (
   job_name => 'delete_characters_schedule',
   job_type => 'PLSQL_BLOCK',
   job_action => 'BEGIN delete_characters_job; END;',
   start_date =>  TO_DATE('20-05-2019 1:00','DD-MM-YYYY HH24:MI'),
   repeat_interval => 'FREQ=DAILY; BYHOUR=2',
   enabled  =>  TRUE);
END;

begin
  DBMS_SCHEDULER.DROP_JOB(job_name => 'delete_characters_schedule');
end;
/* character */

create or replace function item_stats_to_string(in_item_id in  rpg_items.item_id%type) return varchar2 is
  cursor stats is select * from RPG_STATS_VIEW where ITEM_ID = in_item_id;
  return_string VARCHAR2(2000);
begin
  select UTILITY_NAME into return_string
    from RPG_ITEMS items join RPG_ITEM_TYPES item_types on items.ITEM_TYPE = item_types.TYPE_ID
                         join RPG_ITEM_UTILITIES item_utilities on item_types.UTILITY_ID = item_utilities.UTILITY_ID
    where ITEM_ID = in_item_id;
    return_string := return_string || chr(13)||chr(10);
  for stat in stats loop
    return_string := return_string ||' ' || stat.NAME || ': ' || stat.VALUE || chr(13)||chr(10);
  end loop;
  return return_string;
end;

create or replace type item_list_record is object (
  item_id number,
  item_level number,
  item_durability varchar(10),
  item_expiration_date varchar2(20),
  item_name varchar2(100),
  item_rarity varchar2(100),
  item_magic varchar2(100),
  item_stats_string varchar2(2000)
);
/
create or replace type item_list as table of item_list_record;
/
drop type item_list;
/

select * from RPG_ITEMS_VIEW;

create or replace procedure get_items(in_character_id in rpg_items.owner_id%type, out_item_list out item_list, in_is_equiped in number) is
begin
  select item_list_record( ITEM_ID, BASE_LEVEL, CURRENT_DURABILITY || '/' || MAXIMUM_DURABILITY,
         nvl(to_char(EXPIRATION_DATE,'DD-MM-YYYY'),'never'),TYPE_NAME,RARITY_NAME,MAGIC_NAME, item_stats_to_string(ITEM_ID))
    bulk collect into out_item_list
  from RPG_ITEMS_VIEW
  where OWNER_ID =  in_character_id and IS_EQUIPPED = in_is_equiped;
end;

create or replace procedure delete_characters_job as
  begin
    delete from RPG_items where EXPIRATION_DATE is not null and EXPIRATION_DATE < sysdate;
  end;

BEGIN
 DBMS_SCHEDULER.CREATE_JOB (
   job_name => 'delete_items_schedule',
   job_type => 'PLSQL_BLOCK',
   job_action => 'BEGIN delete_items_job; END;',
   start_date =>  TO_DATE('20-05-2019 1:00','DD-MM-YYYY HH24:MI'),
   repeat_interval => 'FREQ=DAILY; BYHOUR=2',
   enabled  =>  TRUE);
END;

begin
  DBMS_SCHEDULER.DROP_JOB(job_name => 'delete_items_schedule');
end;

create or replace function get_equip_type(in_item_id in rpg_items.item_id%type)
return varchar2 is
  type_name varchar2(20);
  utility_name varchar2(20);
begin
  select TYPE_NAME,UTILITY_NAME into type_name, utility_name from RPG_ITEMS_VIEW where in_item_id = ITEM_ID;
  if(lower(utility_name) = 'attack') then
    return lower(utility_name);
  else
    return lower(type_name);
  end if;
end;


create or replace procedure equip_item(in_character_id in rpg_items.owner_id%type, in_item_id in rpg_items.item_id%type) is
  equip_type varchar2(20) := get_equip_type(in_item_id);
  equiped_item_id rpg_items.owner_id%type;
  character_lvl number;
  item_lvl number;
begin
  select CHARACTER_LEVEL into character_lvl from RPG_CHARACTERS where CHARACTER_ID = in_character_id;
  select BASE_LEVEL into item_lvl from RPG_ITEMS where ITEM_ID = in_item_id;
  if(character_lvl < item_lvl) then
    raise_application_error(-20004,'Ai nivel prea mic pentru a folosi acest item ');
  end if;
  select ITEM_ID into equiped_item_id from RPG_ITEMS
  where get_equip_type(item_id) = equip_type and IS_EQUIPPED = 1 and OWNER_ID = in_character_id;
  update RPG_ITEMS set IS_EQUIPPED = 0 where ITEM_ID = equiped_item_id;
  update RPG_ITEMS set IS_EQUIPPED = 1 where ITEM_ID = in_item_id;
  exception when no_data_found then
    update RPG_ITEMS set IS_EQUIPPED = 1 where ITEM_ID = in_item_id;
end;

-- create or replace type character_stats is object (
--   character_health number,
--   user_gold number,
--
-- )

create or replace procedure sell_item(in_item_id in rpg_items.item_id%type) is
  owner_id number;
  v_price number;
  item_rarity number;
  item_level number;
  item_durability_procentage number;
  item_days_util_expiration number;
begin
  select owner_id,RARITY_ID,base_level,current_durability/maximum_durability, nvl(ceil(trunc(expiration_date) - sysdate) + 1, 100)
  INTO owner_id,item_rarity,item_level,item_durability_procentage,item_days_util_expiration
  from rpg_items join rpg_item_types on rpg_items.item_type = rpg_item_types.type_id
    join rpg_item_utilities on rpg_item_types.utility_id = rpg_item_utilities.utility_id
    join rpg_item_rarity on rpg_items.item_rarity = rpg_item_rarity.rarity_id
    join rpg_magic_types on rpg_items.item_magic_type = rpg_magic_types.magic_id
  where in_item_id = RPG_ITEMS.ITEM_ID;
  v_price := item_rarity*(item_level + item_days_util_expiration)*item_durability_procentage;
  DBMS_OUTPUT.PUT_LINE(v_price);
  update rpg_characters set GOLD = GOLD + v_price where owner_id = CHARACTER_ID;
  delete from RPG_ITEMS where in_item_id = ITEM_ID;
end;

create or replace procedure update_item(in_item_id in rpg_items.item_id%type) is
  rand number;
  owner_id number;
  owner_gold number;
  v_price number;
  item_rarity number;
  item_level number;
  item_durability number;
  item_exp_date date;

  type arr_stat_types is table of rpg_stat_types.TYPE_ID%type;
  stat_types arr_stat_types;
  p_stat_num rpg_item_rarity.STATS_NUMBER%type;
  p_num_options number;
  p_option number;
  p_item_utility number;
  p_any_utility number;
  p_item_type number;

  p_min number;
  p_max number;
  p_type_name varchar2(200);

begin
    select OWNER_ID,ITEM_RARITY,BASE_LEVEL,MAXIMUM_DURABILITY,EXPIRATION_DATE, ITEM_TYPE
    into owner_id, item_rarity,item_level,item_durability,item_exp_date, p_item_type
    from RPG_ITEMS
    where in_item_id = ITEM_ID;

    select GOLD into owner_gold
    from RPG_CHARACTERS where character_id = owner_id;

    v_price := item_rarity*(item_level + nvl(ceil(trunc(item_exp_date) - sysdate) + 1, 100));
    if(v_price > owner_gold) then
      raise_application_error(-20006,'Nu aveti '|| v_price ||' gold');
    else
      update RPG_CHARACTERS set GOLD = GOLD - v_price where owner_id = CHARACTER_ID;
    end if;

    if(DBMS_RANDOM.value(1, 100) > item_level / 2) then

      rand := DBMS_RANDOM.value(1, 10);
      if(floor(item_level + rand) <= 100) then
        item_level := floor(item_level + rand);
      else
        item_level := 100;
      end if;

      rand := DBMS_RANDOM.value(0, 3);
      if(floor(item_rarity + rand) <= 4) then
        item_rarity := floor(item_rarity + rand);
      else
        item_rarity := 4;
      end if;

      item_durability := 10 * (item_level + trunc(DBMS_RANDOM.value(1,10)));

      if ( item_exp_date is not null and DBMS_RANDOM.value(0,1) <= 0.9 ) then
        item_exp_date := sysdate + trunc(DBMS_RANDOM.value(1,31));
      else
        item_exp_date := null;
      end if;

      update RPG_ITEMS set BASE_LEVEL = item_level, ITEM_RARITY = item_rarity, CURRENT_DURABILITY = item_durability,
                           MAXIMUM_DURABILITY = item_durability, EXPIRATION_DATE = item_exp_date
           where ITEM_ID = in_item_id;

      select UTILITY_ID into p_item_utility from RPG_ITEM_TYPES where p_item_type = TYPE_ID;
      select UTILITY_ID into p_any_utility from RPG_ITEM_UTILITIES where UTILITY_NAME = 'any';
      if ( p_item_utility = p_any_utility) then
        select TYPE_ID
        bulk collect into stat_types
        from RPG_STAT_TYPES;
      else
        select TYPE_ID
        bulk collect into stat_types
        from RPG_STAT_TYPES
        where p_item_utility = UTILITY_ID;
      end if;

      delete from RPG_ITEM_STATS where in_item_id = ITEM_ID;
      DBMS_OUTPUT.PUT_LINE(item_rarity);
      select STATS_NUMBER into p_stat_num from RPG_ITEM_RARITY where item_rarity = RARITY_ID;

      p_num_options := stat_types.COUNT;
      for i in 0..p_stat_num loop
        p_option := trunc(DBMS_RANDOM.value(1, p_num_options + 1));
        loop
          p_option := mod(p_option + 1, p_num_options + 1);
          if p_option = 0 then
            p_option := 1;
          end if;
          exit when stat_types.exists(p_option);
        end loop;

        select MIN_BASE_VALUE, MAX_BASE_VALUE, NAME into p_min , p_max, p_type_name
        from RPG_STAT_TYPES
        where p_option = TYPE_ID;

        if p_type_name in ('attack damage', 'critical damage', 'armor breaking damage', 'armor','health') then
          insert into rpg_item_stats values (in_item_id,p_option,item_level*round(DBMS_RANDOM.value(p_min,p_max),2));
        else
          insert into rpg_item_stats values (in_item_id,p_option,round(DBMS_RANDOM.value(p_min,p_max),2));
        end if;

        stat_types.delete(p_option);
      end loop;
    else
      delete from RPG_ITEMS where ITEM_ID = in_item_id;
      commit ;
      raise_application_error(-20006,'Itemul a fost distrus in timp ce era imbunatatit');
    end if;
end;

create or replace procedure buy_item(in_character_id in rpg_items.OWNER_ID%type,in_rarity_name in rpg_item_rarity.rarity_name%type) is
  -- for item initialisation
  p_base_level rpg_items.base_level%type;
  p_item_type rpg_items.ITEM_TYPE%type;
  p_item_rarity rpg_items.ITEM_RARITY%type;
  p_item_magic_type rpg_items.ITEM_MAGIC_TYPE%type;
  p_expiration_date rpg_items.EXPIRATION_DATE%type;
  p_durability rpg_items.MAXIMUM_DURABILITY%type;
  p_stat_num rpg_item_rarity.STATS_NUMBER%type;

  -- for stats initialisation
  type arr_stat_types is table of rpg_stat_types.TYPE_ID%type;

  stat_types arr_stat_types;

  p_item_utility number;
  p_any_utility number;
  p_num_options number;
  p_option number;

  p_min number;
  p_max number;
  p_type_name varchar2(200);

  p_price number;
  p_owner_gold number;
begin
  -- verificam daca userul are destui bani
    select GOLD, CHARACTER_LEVEL into p_owner_gold, p_base_level
    from RPG_CHARACTERS where character_id = in_character_id;
    select RARITY_ID into p_item_rarity from RPG_ITEM_RARITY where lower(RARITY_NAME) = lower(in_rarity_name);
    p_price := p_item_rarity*(p_base_level + 100);
    if(p_price > p_owner_gold) then
      raise_application_error(-20006,'Nu aveti '|| p_price ||' gold');
    else
      update RPG_CHARACTERS set GOLD = GOLD - p_price where in_character_id = CHARACTER_ID;
    end if;
  -- random item data without the stats
  p_base_level := trunc(DBMS_RANDOM.value(p_base_level,101));
  p_item_type := trunc(DBMS_RANDOM.value(1, 18));
  p_item_rarity := trunc(DBMS_RANDOM.value(p_item_rarity, 5));
  p_item_magic_type := trunc(DBMS_RANDOM.value(1, 6));
  if ( DBMS_RANDOM.value(0,1) <= 0.9 ) then
    p_expiration_date := sysdate + trunc(DBMS_RANDOM.value(1,31));
  else
    p_expiration_date := null;
  end if;
  p_durability := 10 * (p_base_level + trunc(DBMS_RANDOM.value(1,10)));

  insert into RPG_ITEMS values (rpg_items_seq.nextval,in_character_id,p_base_level,p_durability,p_durability,p_expiration_date,p_item_type,
                                p_item_rarity,p_item_magic_type,0);
  -- random item stats

  select UTILITY_ID into p_item_utility from RPG_ITEM_TYPES where p_item_type = TYPE_ID;
  select UTILITY_ID into p_any_utility from RPG_ITEM_UTILITIES where UTILITY_NAME = 'any';
  if ( p_item_utility = p_any_utility) then
    select TYPE_ID
    bulk collect into stat_types
    from RPG_STAT_TYPES;
  else
    select TYPE_ID
    bulk collect into stat_types
    from RPG_STAT_TYPES
    where p_item_utility = UTILITY_ID;
  end if;

  select STATS_NUMBER into p_stat_num from RPG_ITEM_RARITY where p_item_rarity = RARITY_ID;

  p_num_options := stat_types.COUNT;
  for i in 0..p_stat_num loop
    p_option := trunc(DBMS_RANDOM.value(1, p_num_options + 1));
    loop
      p_option := mod(p_option + 1, p_num_options + 1);
      if p_option = 0 then
        p_option := 1;
      end if;
      exit when stat_types.exists(p_option);
    end loop;

    select MIN_BASE_VALUE, MAX_BASE_VALUE, NAME into p_min , p_max, p_type_name
    from RPG_STAT_TYPES
    where p_option = TYPE_ID;

    if p_type_name in ('attack damage', 'critical damage', 'armor breaking damage', 'armor','health') then
      insert into rpg_item_stats values (rpg_items_seq.currval,p_option,p_base_level*round(DBMS_RANDOM.value(p_min,p_max),2));
    else
      insert into rpg_item_stats values (rpg_items_seq.currval,p_option,round(DBMS_RANDOM.value(p_min,p_max),2));
    end if;

    stat_types.delete(p_option);
  end loop;
  exception when no_data_found then
    p_num_options :=0;
    select count(*) into p_num_options from RPG_ITEM_RARITY where lower(RARITY_NAME) = lower(in_rarity_name);
    if(p_num_options = 0) then
      raise_application_error(-20007, 'Poti introduce ca raritate dorita doar: \"common\", \"rare\", \"epic\", \"legendary\"');
    else
      raise no_data_found ;
    end if;
end;