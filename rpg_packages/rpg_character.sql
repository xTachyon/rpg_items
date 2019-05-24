create or replace package rpg_character as
  function item_stats_to_string(in_item_id in  rpg_items.item_id%type) return varchar2;
  procedure get_items(in_character_id in rpg_items.owner_id%type, out_item_list out item_list, in_is_equiped in number);
  function get_equip_type(in_item_id in rpg_items.item_id%type) return varchar2;
  procedure equip_item(in_character_id in rpg_items.owner_id%type, in_item_id in rpg_items.item_id%type);
  procedure sell_item(in_item_id in rpg_items.item_id%type);
  procedure update_item(in_item_id in rpg_items.item_id%type);
  procedure buy_item(in_character_id in rpg_items.OWNER_ID%type,in_rarity_name in rpg_item_rarity.rarity_name%type);
  function get_stats_report_from_item(in_item_id in rpg_items.item_id%type) return stats_report;
  function add_stats_reports(in_stats_1 in stats_report, in_stats_2 in stats_report) return stats_report;
  function get_stats_report_for_character(in_character_id in rpg_items.OWNER_ID%type) return stats_report;
  function character_stats_to_string(in_character_id in rpg_items.OWNER_ID%type) return clob;
  function number_with_sign(in_number in number) return varchar2;
  function compare_items(in_item_id1 in rpg_items.item_id%type, in_item_id2 in rpg_items.item_id%type,
              in_owner_id in rpg_items.owner_id%type) return clob;
end;
  
create or replace package body rpg_character as
function item_stats_to_string(in_item_id in  rpg_items.item_id%type) return varchar2 is
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

procedure get_items(in_character_id in rpg_items.owner_id%type, out_item_list out item_list, in_is_equiped in number) is
begin
  select item_list_record( ITEM_ID, BASE_LEVEL, CURRENT_DURABILITY || '/' || MAXIMUM_DURABILITY,
         nvl(to_char(EXPIRATION_DATE,'DD-MM-YYYY'),'never'),TYPE_NAME,RARITY_NAME,MAGIC_NAME, item_stats_to_string(ITEM_ID))
    bulk collect into out_item_list
  from RPG_ITEMS_VIEW
  where OWNER_ID =  in_character_id and IS_EQUIPPED = in_is_equiped;
end;

function get_equip_type(in_item_id in rpg_items.item_id%type)
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


procedure equip_item(in_character_id in rpg_items.owner_id%type, in_item_id in rpg_items.item_id%type) is
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

procedure sell_item(in_item_id in rpg_items.item_id%type) is
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

procedure update_item(in_item_id in rpg_items.item_id%type) is
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

procedure buy_item(in_character_id in rpg_items.OWNER_ID%type,in_rarity_name in rpg_item_rarity.rarity_name%type) is
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
  p_base_level := trunc(DBMS_RANDOM.value(p_base_level-10,101));
  if(p_base_level < 1) then
    p_base_level := 1;
  end if;
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

function get_stats_report_from_item(in_item_id in rpg_items.item_id%type) return stats_report is
  stats stats_report;
  cursor item_stats is select rsv.name, rsv.value from RPG_STATS_VIEW rsv where in_item_id = item_id;
begin
  stats := stats_report(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,ARR_NUMBER());
  for item_stat in item_stats loop
    case item_stat.NAME
      when 'attack damage' then stats.attack_damage := nvl(stats.attack_damage,0) + trunc(item_stat.value,2);
      when 'critical damage' then stats.critical_damage := nvl(stats.critical_damage,0) + trunc(item_stat.value,2);
      when 'critical chance' then stats.critical_chance := nvl(stats.critical_chance,0) + trunc(item_stat.value,2);
      when 'bleeding damage' then stats.bleeding_damage := nvl(stats.bleeding_damage,0) + trunc(item_stat.value,2);
      when 'bleeding chance' then stats.bleeding_chance := nvl(stats.bleeding_chance,0) + trunc(item_stat.value,2);
      when 'bleeding duration' then stats.bleeding_duration := nvl(stats.bleeding_duration,0) + trunc(item_stat.value,2);
      when 'poisonous damage' then stats.poisonous_damage := nvl(stats.poisonous_damage,0) + trunc(item_stat.value,2);
      when 'poison chance' then stats.poison_chance := nvl(stats.poison_chance,0) + trunc(item_stat.value,2);
      when 'poison duration' then stats.poison_duration := nvl(stats.poison_duration,0) + trunc(item_stat.value,2);
      when 'stun chance' then stats.stun_chance := nvl(stats.stun_chance,0) + trunc(item_stat.value,2);
      when 'stun duration' then stats.stun_duration := nvl(stats.stun_duration,0) + trunc(item_stat.value,2);
      when 'double hit chance' then stats.double_hit_chance := nvl(stats.double_hit_chance,0) + trunc(item_stat.value,2);
      when 'armor breaking damage' then stats.armor_breaking_damage := nvl(stats.armor_breaking_damage,0) + trunc(item_stat.value,2);
      when 'defence breaking chance' then stats.defence_breaking_chance := nvl(stats.defence_breaking_chance,0) + trunc(item_stat.value,2);
      when 'enrage' then stats.enrage := nvl(stats.enrage,0) + trunc(item_stat.value,2);
      when 'armor' then stats.armor := nvl(stats.armor,0) + trunc(item_stat.value,2);
      when 'health' then stats.health := nvl(stats.health,0) + trunc(item_stat.value,2);
      when 'health regen' then stats.health_regen := nvl(stats.health_regen,0) + trunc(item_stat.value,2);
      when 'armor regen' then stats.armor_regen := nvl(stats.armor_regen,0) + trunc(item_stat.value,2);
      when 'parry chance' then stats.parry_chance := nvl(stats.parry_chance,0) + trunc(item_stat.value,2);
      when 'stun chance reduction' then stats.stun_chance_reduction := nvl(stats.stun_chance_reduction,0) + trunc(item_stat.value,2);
      when 'bleeding chance reduction' then stats.bleeding_chance_reduction := nvl(stats.bleeding_chance_reduction,0) + trunc(item_stat.value,2);
      when 'poison chance reduction' then stats.poison_chance_reduction := nvl(stats.poison_chance_reduction,0) + trunc(item_stat.value,2);
      when 'damage reflection' then stats.damage_reflection := nvl(stats.damage_reflection,0) + trunc(item_stat.value,2);
    end case;
  end loop;
  select ITEM_MAGIC_TYPE bulk collect into stats.magic_types from RPG_ITEMS where in_item_id = item_id;
  return stats;
end;

function add_stats_reports(in_stats_1 in stats_report, in_stats_2 in stats_report)
return stats_report is
  stats stats_report;
begin
  stats := stats_report(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,ARR_NUMBER());
  stats.character_health := nvl(in_stats_1.character_health,0) + nvl(in_stats_2.character_health,0);
  stats.user_gold := nvl(in_stats_1.user_gold,0) + nvl(in_stats_2.user_gold,0);

  stats.attack_damage := nvl(in_stats_1.attack_damage,0) + nvl(in_stats_2.attack_damage,0);
  stats.critical_damage := nvl(in_stats_1.critical_damage,0) + nvl(in_stats_2.critical_damage,0);
  stats.critical_chance := nvl(in_stats_1.critical_chance,0) + nvl(in_stats_2.critical_chance,0);
  stats.bleeding_damage := nvl(in_stats_1.bleeding_damage,0) + nvl(in_stats_2.bleeding_damage,0);
  stats.bleeding_chance := nvl(in_stats_1.bleeding_chance,0) + nvl(in_stats_2.bleeding_chance,0);
  stats.bleeding_duration := nvl(in_stats_1.bleeding_duration,0) + nvl(in_stats_2.bleeding_duration,0);
  stats.poisonous_damage := nvl(in_stats_1.poisonous_damage,0) + nvl(in_stats_2.poisonous_damage,0);
  stats.poison_chance := nvl(in_stats_1.poison_chance,0) + nvl(in_stats_2.poison_chance,0);
  stats.poison_duration := nvl(in_stats_1.poison_duration,0) + nvl(in_stats_2.poison_duration,0);
  stats.stun_chance := nvl(in_stats_1.stun_chance,0) + nvl(in_stats_2.stun_chance,0);
  stats.stun_duration := nvl(in_stats_1.stun_duration,0) + nvl(in_stats_2.stun_duration,0);
  stats.double_hit_chance := nvl(in_stats_1.double_hit_chance,0) + nvl(in_stats_2.double_hit_chance,0);
  stats.armor_breaking_damage := nvl(in_stats_1.armor_breaking_damage,0) + nvl(in_stats_2.armor_breaking_damage,0);
  stats.defence_breaking_chance := nvl(in_stats_1.defence_breaking_chance,0) + nvl(in_stats_2.defence_breaking_chance,0);
  stats.enrage := nvl(in_stats_1.enrage,0) + nvl(in_stats_2.enrage,0);
  stats.armor := nvl(in_stats_1.armor,0) + nvl(in_stats_2.armor,0);
  stats.health := nvl(in_stats_1.health,0) + nvl(in_stats_2.health,0);
  stats.health_regen := nvl(in_stats_1.health_regen,0) + nvl(in_stats_2.health_regen,0);
  stats.armor_regen := nvl(in_stats_1.armor_regen,0) + nvl(in_stats_2.armor_regen,0);
  stats.parry_chance := nvl(in_stats_1.parry_chance,0) + nvl(in_stats_2.parry_chance,0);
  stats.stun_chance_reduction := nvl(in_stats_1.stun_chance_reduction,0) + nvl(in_stats_2.stun_chance_reduction,0);
  stats.bleeding_chance_reduction := nvl(in_stats_1.bleeding_chance_reduction,0) + nvl(in_stats_2.bleeding_chance_reduction,0);
  stats.poison_chance_reduction := nvl(in_stats_1.poison_chance_reduction,0) + nvl(in_stats_2.poison_chance_reduction,0);
  stats.damage_reflection := nvl(in_stats_1.damage_reflection,0) + nvl(in_stats_2.damage_reflection,0);

  stats.MAGIC_TYPES := in_stats_1.MAGIC_TYPES multiset union distinct in_stats_2.MAGIC_TYPES;

  return stats;
end;

function get_stats_report_for_character(in_character_id in rpg_items.OWNER_ID%type)
return stats_report is
  stats stats_report;
  cursor items is select ITEM_ID from rpg_items where OWNER_ID = in_character_id and IS_EQUIPPED = 1;
begin
  stats := stats_report(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,ARR_NUMBER());
  select trunc(GOLD,2), trunc(10*CHARACTER_LEVEL,2), trunc(CHARACTER_LEVEL,2)
  into stats.USER_GOLD, stats.CHARACTER_HEALTH, stats.ATTACK_DAMAGE
  from RPG_CHARACTERS where CHARACTER_ID = in_character_id;

  for item in items loop
    stats := add_stats_reports(stats,get_stats_report_from_item(item.ITEM_ID));
  end loop;
  stats.CHARACTER_HEALTH := stats.CHARACTER_HEALTH + stats.HEALTH;
  return stats;
end;

function character_stats_to_string(in_character_id in rpg_items.OWNER_ID%type)
return clob is
  stats_string clob;
  stats stats_report;
  p_name varchar2(200);
  p_level varchar2(200);
  p_magic varchar2(200);
begin
  stats := get_stats_report_for_character(in_character_id);
  stats_string := '';
  select NAME, CHARACTER_LEVEL into p_name, p_level from RPG_CHARACTERS where in_character_id = CHARACTER_ID;
  stats_string := stats_string || 'Name: ' || p_name || chr(13)||chr(10);
  stats_string := stats_string || 'Level: ' || trunc(p_level,2) || chr(13)||chr(10);
  stats_string := stats_string || 'Gold: ' || stats.USER_GOLD || chr(13)||chr(10);
  stats_string := stats_string || 'Health: ' || stats.CHARACTER_HEALTH || chr(13)||chr(10);

  stats_string := stats_string || 'attack_damage: ' || stats.attack_damage || chr(13)||chr(10);
  stats_string := stats_string || 'critical_damage: ' || stats.critical_damage || chr(13)||chr(10);
  stats_string := stats_string || 'critical_chance: ' || stats.critical_chance || chr(13)||chr(10);
  stats_string := stats_string || 'bleeding_damage: ' || stats.bleeding_damage || chr(13)||chr(10);
  stats_string := stats_string || 'bleeding_chance: ' || stats.bleeding_chance || chr(13)||chr(10);
  stats_string := stats_string || 'bleeding_duration: ' || stats.bleeding_duration || chr(13)||chr(10);
  stats_string := stats_string || 'poisonous_damage: ' || stats.poisonous_damage || chr(13)||chr(10);
  stats_string := stats_string || 'poison_chance: ' || stats.poison_chance || chr(13)||chr(10);
  stats_string := stats_string || 'poison_duration: ' || stats.poison_duration || chr(13)||chr(10);
  stats_string := stats_string || 'stun_chance: ' || stats.stun_chance || chr(13)||chr(10);
  stats_string := stats_string || 'stun_duration: ' || stats.stun_duration || chr(13)||chr(10);
  stats_string := stats_string || 'double_hit_chance: ' || stats.double_hit_chance || chr(13)||chr(10);
  stats_string := stats_string || 'armor_breaking_damage: ' || stats.armor_breaking_damage || chr(13)||chr(10);
  stats_string := stats_string || 'defence_breaking_chance: ' || stats.defence_breaking_chance || chr(13)||chr(10);
  stats_string := stats_string || 'enrage: ' || stats.enrage || chr(13)||chr(10);
  stats_string := stats_string || 'armor: ' || stats.armor || chr(13)||chr(10);
  stats_string := stats_string || 'health_regen: ' || stats.health_regen || chr(13)||chr(10);
  stats_string := stats_string || 'armor_regen: ' || stats.armor_regen || chr(13)||chr(10);
  stats_string := stats_string || 'parry_chance: ' || stats.parry_chance || chr(13)||chr(10);
  stats_string := stats_string || 'stun_chance_reduction: ' || stats.stun_chance_reduction || chr(13)||chr(10);
  stats_string := stats_string || 'bleeding_chance_reduction: ' || stats.bleeding_chance_reduction || chr(13)||chr(10);
  stats_string := stats_string || 'poison_chance_reduction: ' || stats.poison_chance_reduction || chr(13)||chr(10);
  stats_string := stats_string || 'damage_reflection: ' || stats.damage_reflection || chr(13)||chr(10);
  stats_string := stats_string || 'magic_types: ';

  if(stats.MAGIC_TYPES is not null and stats.MAGIC_TYPES.COUNT > 0) then
    for i in stats.magic_types.FIRST .. stats.magic_types.LAST loop
      select MAGIC_NAME into p_magic from RPG_MAGIC_TYPES where MAGIC_ID = stats.MAGIC_TYPES(i);
      stats_string := stats_string || p_magic || ' ';
    end loop;
  end if;
  stats_string := stats_string || chr(13)||chr(10);
  return stats_string;
end;

function number_with_sign(in_number in number)
return varchar2 is
begin
  if(sign(in_number) = +1)then
    return '+' || in_number;
  else
    return in_number;
  end if;
end;

function compare_items(in_item_id1 in rpg_items.item_id%type, in_item_id2 in rpg_items.item_id%type,
              in_owner_id in rpg_items.owner_id%type)
return clob is
  output_string clob;
  stats1 stats_report;
  stats2 stats_report;

  magic_aux ARR_NUMBER;
  p_magic varchar2(200);
  p_owner rpg_items.owner_id%type;
begin
    if(in_item_id1 = in_item_id2) then
      raise_application_error(-20007,'Introduceti iteme diferite!');
    end if;
    select OWNER_ID into p_owner from rpg_items where ITEM_ID = in_item_id1;
    if(p_owner <> in_owner_id) then
      raise_application_error(-20007,'Unul din iteme a fost introdus gresit');
    end if;
    select OWNER_ID into p_owner from rpg_items where ITEM_ID = in_item_id2;
    if(p_owner <> in_owner_id) then
      raise_application_error(-20007,'Unul din iteme a fost introdus gresit');
    end if;
    -- item 1 is compared with item 2
    output_string := 'Daca ati folosi item-ul '|| in_item_id1 ||' in defavoarea item-ului '|| in_item_id2
                       ||' ati avea urmatoarele rezultate:'|| chr(13)||chr(10);
    stats1 := get_stats_report_from_item(in_item_id1);
    stats2 := get_stats_report_from_item(in_item_id2);

    output_string := output_string || 'attack_damage: ' || number_with_sign(stats1.attack_damage  - stats2.attack_damage) || chr(13)||chr(10);
    output_string := output_string || 'critical_damage: ' || number_with_sign(stats1.critical_damage - stats2.critical_damage) || chr(13)||chr(10);
    output_string := output_string || 'critical_chance: ' || number_with_sign(stats1.critical_chance - stats2.critical_chance) || chr(13)||chr(10);
    output_string := output_string || 'bleeding_damage: ' || number_with_sign(stats1.bleeding_damage - stats2.bleeding_damage) || chr(13)||chr(10);
    output_string := output_string || 'bleeding_chance: ' || number_with_sign(stats1.bleeding_chance - stats2.bleeding_chance) || chr(13)||chr(10);
    output_string := output_string || 'bleeding_duration: ' || number_with_sign(stats1.bleeding_duration - stats2.bleeding_duration) || chr(13)||chr(10);
    output_string := output_string || 'poisonous_damage: ' || number_with_sign(stats1.poisonous_damage - stats2.poisonous_damage)|| chr(13)||chr(10);
    output_string := output_string || 'poison_chance: ' || number_with_sign(stats1.poison_chance - stats2.poison_chance)|| chr(13)||chr(10);
    output_string := output_string || 'poison_duration: ' || number_with_sign(stats1.poison_duration - stats2.poison_duration)|| chr(13)||chr(10);
    output_string := output_string || 'stun_chance: ' || number_with_sign(stats1.stun_chance - stats2.stun_chance) || chr(13)||chr(10);
    output_string := output_string || 'stun_duration: ' || number_with_sign(stats1.stun_duration - stats2.stun_duration) || chr(13)||chr(10);
    output_string := output_string || 'double_hit_chance: ' || number_with_sign(stats1.double_hit_chance - stats2.double_hit_chance) || chr(13)||chr(10);
    output_string := output_string || 'armor_breaking_damage: ' || number_with_sign(stats1.armor_breaking_damage - stats2.armor_breaking_damage) || chr(13)||chr(10);
    output_string := output_string || 'defence_breaking_chance: ' || number_with_sign(stats1.defence_breaking_chance - stats2.defence_breaking_chance) || chr(13)||chr(10);
    output_string := output_string || 'enrage: ' || number_with_sign(stats1.enrage - stats2.enrage) || chr(13)||chr(10);
    output_string := output_string || 'health: ' || number_with_sign(stats1.health - stats2.health) || chr(13)||chr(10);
    output_string := output_string || 'armor: ' || number_with_sign(stats1.armor - stats2.armor) || chr(13)||chr(10);
    output_string := output_string || 'health_regen: ' || number_with_sign(stats1.health_regen - stats2.health_regen) || chr(13)||chr(10);
    output_string := output_string || 'armor_regen: ' || number_with_sign(stats1.armor_regen - stats2.armor_regen) || chr(13)||chr(10);
    output_string := output_string || 'parry_chance: ' || number_with_sign(stats1.parry_chance - stats2.parry_chance) || chr(13)||chr(10);
    output_string := output_string || 'stun_chance_reduction: ' || number_with_sign(stats1.stun_chance_reduction - stats2.stun_chance_reduction) || chr(13)||chr(10);
    output_string := output_string || 'bleeding_chance_reduction: ' || number_with_sign(stats1.bleeding_chance_reduction - stats2.bleeding_chance_reduction) || chr(13)||chr(10);
    output_string := output_string || 'poison_chance_reduction: ' || number_with_sign(stats1.poison_chance_reduction - stats2.poison_chance_reduction) || chr(13)||chr(10);
    output_string := output_string || 'damage_reflection: ' || number_with_sign(stats1.damage_reflection - stats2.damage_reflection) || chr(13)||chr(10);
    output_string := output_string || 'magic_types: ';
    output_string := output_string || chr(13)||chr(10);

    magic_aux := stats1.MAGIC_TYPES multiset except distinct stats2.MAGIC_TYPES;
    if(magic_aux is not null and magic_aux.COUNT > 0) then
        for i in magic_aux.FIRST .. magic_aux.LAST loop
          select MAGIC_NAME into p_magic from RPG_MAGIC_TYPES where MAGIC_ID = magic_aux(i);
          output_string := output_string || '+' || p_magic || ' ';
        end loop;
      end if;
    output_string := output_string || chr(13)||chr(10);

    magic_aux := stats2.MAGIC_TYPES multiset except distinct stats1.MAGIC_TYPES;
    if(magic_aux is not null and magic_aux.COUNT > 0) then
        for i in magic_aux.FIRST .. magic_aux.LAST loop
          select MAGIC_NAME into p_magic from RPG_MAGIC_TYPES where MAGIC_ID = magic_aux(i);
          output_string := output_string || '-' || p_magic || ' ';
        end loop;
      end if;
    output_string := output_string || chr(13)||chr(10);

    return output_string;

    exception when no_data_found then
      select count(*) into p_owner from rpg_items where ITEM_ID in (in_item_id1,in_item_id2);
      if(p_owner <> 2) then
        raise_application_error(-20007,'Unul din iteme a fost introdus gresit');
      end if;
end;

end;