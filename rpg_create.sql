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
  delete from rpg_magic_types;
  FOR i IN weakness_list.first .. weakness_list.last loop
    insert into rpg_magic_types values (rpg_magic_types_seq.nextval,lower(weakness_list(i)));
  end loop;
END;
/

begin
  DBMS_OUTPUT.put_line('rpg_magic_types has '|| rpg_magic_types_seq.currval || ' elements!');
end;
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
  delete from rpg_magic_weaknesses;
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

