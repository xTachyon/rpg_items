-- sequences for the ids of the main tables
drop sequence rpg_users_seq;
/
drop sequence rpg_friends_seq;
/
drop sequence rpg_classes_seq;
/
drop sequence rpg_characters_seq;
/
drop sequence rpg_items_seq;
/
drop sequence rpg_item_utilities_seq;
/
drop sequence rpg_item_types_seq;
/
drop sequence rpg_item_rarity_seq;
/
drop sequence rpg_magic_types_seq;
/
drop sequence rpg_stat_types_seq;
/
drop sequence rpg_item_stats_seq;
/
drop sequence rpg_class_stats_seq;
/
drop sequence rpg_magic_weaknesses_seq;
/

create sequence rpg_users_seq start with 1;
/
create sequence rpg_friends_seq start with 1;
/
create sequence rpg_classes_seq start with 1;
/
create sequence rpg_characters_seq start with 1;
/
create sequence rpg_items_seq start with 1;
/
create sequence rpg_item_utilities_seq start with 1;
/
create sequence rpg_item_types_seq start with 1;
/
create sequence rpg_item_rarity_seq start with 1;
/
create sequence rpg_magic_types_seq start with 1;
/
create sequence rpg_stat_types_seq start with 1;
/
create sequence rpg_item_stats_seq start with 1;
/
create sequence rpg_class_stats_seq start with 1;
/
create sequence rpg_magic_weaknesses_seq start with 1;
/


-- create data for our tables
-- set serveroutput on;
create or replace type arr_varchar2 is table of varchar2(200);
-- =====================================================================================================================

-- magic types:
drop sequence rpg_magic_types_seq;
/
create sequence rpg_magic_types_seq start with 1;
/
DECLARE
  weakness_list arr_varchar2 := arr_varchar2('common','fire','water','air','earth');
BEGIN
  -- delete from rpg_magic_types;
  FOR i IN weakness_list.first .. weakness_list.last loop
    insert into rpg_magic_types values (rpg_magic_types_seq.nextval,lower(weakness_list(i)));
  end loop;
END;
/

-- select * from RPG_MAGIC_TYPES;

-- =====================================================================================================================

-- magic weaknesses
drop sequence rpg_magic_weaknesses_seq;
/
create sequence rpg_magic_weaknesses_seq start with 1;
/
-- helpful procedure
create or replace procedure add_magic_weakness(name_weakness_of in varchar2, name_weakness_to in varchar2) is
  weakness_of rpg_magic_types.magic_id%type := 0;
  weakness_to rpg_magic_types.magic_id%type := 0;
begin
  select MAGIC_ID into weakness_of from RPG_MAGIC_TYPES where MAGIC_NAME = lower(name_weakness_of);
  select MAGIC_ID into weakness_to from RPG_MAGIC_TYPES where MAGIC_NAME = lower(name_weakness_to);
  if (weakness_of<>0 and weakness_to<>0) then
    insert into RPG_MAGIC_WEAKNESSES values (rpg_magic_weaknesses_seq.nextval,weakness_of,weakness_to);
  else
    DBMS_OUTPUT.put_line('add_magic_weakness: ERROR - '|| name_weakness_of ||' or '||name_weakness_to||' is not a valid magic type!');
  end if;
end;
/

BEGIN
  -- delete from rpg_magic_weaknesses;
  add_magic_weakness('fire','water');
  add_magic_weakness('water','earth');
  add_magic_weakness('earth','air');
  add_magic_weakness('air','fire');
END;
/

-- select * from RPG_MAGIC_WEAKNESSES;

-- =====================================================================================================================

-- item utilities:
-- there will be mainly 3 utilities: attack, defence and any

drop sequence rpg_item_utilities_seq;
/
create sequence rpg_item_utilities_seq start with 1;
/
declare
  utilities_list arr_varchar2 := arr_varchar2('attack','defence','any');
begin
  -- delete from RPG_ITEM_UTILITIES;
  FOR i IN utilities_list.first .. utilities_list.last loop
    insert into RPG_ITEM_UTILITIES values (rpg_item_utilities_seq.nextval,lower(utilities_list(i)));
  end loop;
end;

-- select * from RPG_ITEM_UTILITIES;

-- =====================================================================================================================

-- item types:

drop sequence rpg_item_types_seq;
/
create sequence rpg_item_types_seq start with 1;
/
declare
  attack_item_list arr_varchar2 := arr_varchar2('sword','dagger','stick','bow','axe','spear','fan','knife','hammer');
  defence_item_list arr_varchar2 := arr_varchar2('helmet','armor','pants','gloves','boots','shield');
  any_item_list arr_varchar2 := arr_varchar2('ring','necklace');
  attack_id RPG_ITEM_UTILITIES.UTILITY_ID%type := 0;
  defence_id RPG_ITEM_UTILITIES.UTILITY_ID%type := 0;
  any_id RPG_ITEM_UTILITIES.UTILITY_ID%type := 0;
begin
  -- delete from RPG_ITEM_TYPES;
  -- getting the ids
  select UTILITY_ID into attack_id from RPG_ITEM_UTILITIES where UTILITY_NAME = lower('attack');
  select UTILITY_ID into defence_id from RPG_ITEM_UTILITIES where UTILITY_NAME = lower('defence');
  select UTILITY_ID into any_id from RPG_ITEM_UTILITIES where UTILITY_NAME = lower('any');
  -- adding the attack items
  FOR i IN attack_item_list.first .. attack_item_list.last loop
    insert into RPG_ITEM_TYPES values (rpg_item_types_seq.nextval,attack_id,attack_item_list(i));
  end loop;
  -- adding the defence items
  FOR i IN defence_item_list.first .. defence_item_list.last loop
    insert into RPG_ITEM_TYPES values (rpg_item_types_seq.nextval,defence_id,defence_item_list(i));
  end loop;
  -- adding the any items
  FOR i IN any_item_list.first .. any_item_list.last loop
    insert into RPG_ITEM_TYPES values (rpg_item_types_seq.nextval,any_id,any_item_list(i));
  end loop;
end;

-- select * from RPG_ITEM_TYPES;

-- =====================================================================================================================

-- stat types:

drop sequence rpg_stat_types_seq;
/
create sequence rpg_stat_types_seq start with 1;
/
declare
  attack_stat_list arr_varchar2 := arr_varchar2('attack damage','critical damage','critical chance','bleeding damage','bleeding chance','bleeding duration','poisonous damage',
    'poison chance','poison duration','stun chance','stun duration','double hit chance','armor breaking damage','defence breaking chance','enrage');
  defence_stat_list arr_varchar2 := arr_varchar2('armor','health','health regen','armor regen','parry chance','stun chance reduction','bleeding chance reduction',
    'poison chance reduction','damage reflection');
  attack_id RPG_ITEM_UTILITIES.UTILITY_ID%type := 0;
  defence_id RPG_ITEM_UTILITIES.UTILITY_ID%type := 0;
begin
  -- delete from RPG_STAT_TYPES;
  -- getting the ids
  select UTILITY_ID into attack_id from RPG_ITEM_UTILITIES where UTILITY_NAME = lower('attack');
  select UTILITY_ID into defence_id from RPG_ITEM_UTILITIES where UTILITY_NAME = lower('defence');
  -- adding the attack stats
  FOR i IN attack_stat_list.first .. attack_stat_list.last loop
    if attack_stat_list(i) like '%chance' or attack_stat_list(i) in ('bleeding damage', 'poisonous damage', 'enrage') then
      -- range for the percentages stats
      insert into RPG_STAT_TYPES values (rpg_stat_types_seq.nextval,attack_id,attack_stat_list(i),0.01,1);
    elsif attack_stat_list(i) like '%duration' then
      -- range for turn-based stats ( duration )
      insert into RPG_STAT_TYPES values (rpg_stat_types_seq.nextval,attack_id,attack_stat_list(i),1,5);
    else
      -- range for damage buffs ( this will be multiplied with the item's level to get the real value )
      insert into RPG_STAT_TYPES values (rpg_stat_types_seq.nextval,attack_id,attack_stat_list(i),1,3);
    end if;
  end loop;
  -- adding the defence stats
  FOR i IN defence_stat_list.first .. defence_stat_list.last loop
    if defence_stat_list(i) not in ('armor','health') then
      -- range for the percentages stats
      insert into RPG_STAT_TYPES values (rpg_stat_types_seq.nextval,defence_id,defence_stat_list(i),0.01,1);
    else
      -- range for health and armor ( this will be multiplied with the item's level to get the real value )
      insert into RPG_STAT_TYPES values (rpg_stat_types_seq.nextval,defence_id,defence_stat_list(i),5,10);
    end if;
  end loop;
end;

-- select * from RPG_STAT_TYPES;

-- =====================================================================================================================

-- item rarity:
drop sequence rpg_item_rarity_seq;
/
create sequence rpg_item_rarity_seq start with 1;
/
DECLARE
  rarity_list arr_varchar2 := arr_varchar2('common','rare','epic','legendary');
BEGIN
  -- delete from rpg_item_rarity;
  insert into RPG_ITEM_RARITY values (rpg_item_rarity_seq.nextval,'common','white',2);
  insert into RPG_ITEM_RARITY values (rpg_item_rarity_seq.nextval,'rare','blue',3);
  insert into RPG_ITEM_RARITY values (rpg_item_rarity_seq.nextval,'epic','purple',4);
  insert into RPG_ITEM_RARITY values (rpg_item_rarity_seq.nextval,'legendary','orange',5);
END;
/

-- select * from RPG_ITEM_RARITY;

create or replace function generate_email return varchar2 as
  names_list arr_varchar2 := arr_varchar2('andrei', 'mihai', 'matei');
  providers_list arr_varchar2 := arr_varchar2('gmail', 'yahoo');

  result varchar2(200);
  r number;
  r2 number;
  r3 number;
BEGIN
  r := DBMS_RANDOM.value(1, names_list.COUNT);
  r2 := DBMS_RANDOM.value(1, names_list.COUNT);
  r3 := DBMS_RANDOM.value(1, providers_list.COUNT);

--   result := names_list(r) || '_' || names_list(r2) || '@' || providers_list(r3) || '.com';
  result := generate_random_string(DBMS_RANDOM.value(5, 20)) || '_' || names_list(r2) || '@' || providers_list(r3) || '.com';


  return result;
END;

select generate_email()
from dual;

create or replace function generate_random_string(string_length number) return varchar2 as
  letters_numbers varchar2(200) := 'abcdefghijklmnopqrstuvwxyz';

  result varchar2(200);
BEGIN
  result := '';

  for i in 1..string_length loop
    result := result || substr(letters_numbers, DBMS_RANDOM.value(1, length(letters_numbers)), 1);
  end loop;

  return result;
END;

-- select generate_random_string(50)
-- from dual;

create or replace procedure generate_user is
  username_list arr_varchar2 := arr_varchar2('tachyon', 'ml997', 'lamp');

  username varchar2(200);
  password varchar2(200);
  email varchar2(200);
BEGIN
  username := generate_random_string(DBMS_RANDOM.value(15, 20));
  password := generate_random_string(DBMS_RANDOM.value(15, 20));
  email := generate_email();

  insert into RPG_USERS
  values (rpg_users_seq.nextval, username, password, email);
END;

begin
  for i in 0..25000 loop
    generate_user();
  end loop;
end;

-- select * from RPG_USERS;

create or replace procedure generate_friendships is
  id1 number;
  id2 number;
  friends_already number;
  countt number;
BEGIN
  select count(*)
  into countt
  from RPG_USERS;

  loop
    id1 := trunc(DBMS_RANDOM.value(0, countt)) + 1;
    id2 := trunc(DBMS_RANDOM.value(0, countt)) + 1;

    exit when id1 <> id2;
  end loop;

  select count(*)
  into friends_already
  from RPG_FRIENDS
  where (USER_ID1 = id1 and USER_ID2 = id2) or (USER_ID1 = id2 and USER_ID2 = id1);

  if friends_already = 0 then
    insert into RPG_FRIENDS
    values (rpg_friends_seq.nextval, id1, id2);
  end if;
END;

begin
  for i in 0..1000 loop
    generate_friendships();
  end loop;
end;

-- select count(*)
-- from RPG_FRIENDS;
--
-- select *
-- from RPG_FRIENDS;

begin
  insert into RPG_CLASSES values (rpg_classes_seq.nextval, 'archer');
  insert into RPG_CLASSES values (rpg_classes_seq.nextval, 'warrior');
  insert into RPG_CLASSES values (rpg_classes_seq.nextval, 'assassin');
  insert into RPG_CLASSES values (rpg_classes_seq.nextval, 'wizard');
end;

create or replace procedure generate_characters is
  cursor c is select USER_ID from RPG_USERS;
  class_count number;

  number_characters number;
  name varchar2(200);
  character_level number;
  classs number;
  gold number;
BEGIN
  select count(*)
  into class_count
  from rpg_classes;

  for row in c loop
    number_characters := DBMS_RANDOM.value(2, 7);
    for i in 0..number_characters loop
      name := generate_random_string(DBMS_RANDOM.value(15, 20));
      character_level := DBMS_RANDOM.value(1, 100);
      classs := trunc(DBMS_RANDOM.value(1, class_count));
--       dbms_output.put_line(classs);
      gold := DBMS_RANDOM.value(1, 342512);

      insert into RPG_CHARACTERS
      values(RPG_CHARACTERS_SEQ.nextval, row.USER_ID, name, character_level, classs, gold, null);
    end loop;
  end loop;
END;

begin
  generate_characters();
end;

-- =====================================================================================================================

-- class stats:
drop sequence RPG_CLASS_STATS_SEQ;
/
create sequence RPG_CLASS_STATS_SEQ start with 1;
/
DECLARE
  cursor classes_list is select CLASS_ID from RPG_CLASSES;
  cursor stats_list is select type_id from RPG_STAT_TYPES;
BEGIN
  -- initialization
  for class in classes_list loop
    for stat in stats_list loop
      insert into RPG_CLASS_STATS values (RPG_CLASS_STATS_SEQ.nextval,class.CLASS_ID,stat.TYPE_ID,0);
    end loop;
  end loop;

END;
/