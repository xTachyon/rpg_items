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
set serveroutput on;
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

