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
-- set serveroutput on;
create or replace type arr_varchar2 is table of varchar2(200);
-- =====================================================================================================================

-- magic types:
drop sequence rpg_magic_types_seq;
/
create sequence rpg_magic_types_seq start with 1;
/
DECLARE
  weakness_list arr_varchar2 := arr_varchar2('common', 'fire', 'water', 'air', 'earth');
BEGIN
  delete from rpg_magic_types;
  FOR i IN weakness_list.first .. weakness_list.last
    loop
      insert into rpg_magic_types values (rpg_magic_types_seq.nextval, lower(weakness_list(i)));
    end loop;
END;
/

begin
  DBMS_OUTPUT.put_line('rpg_magic_types has ' || rpg_magic_types_seq.currval || ' elements!');
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
  if (weakness_of <> 0 and weakness_to <> 0) then
    insert into RPG_MAGIC_WEAKNESSES values (rpg_magic_weaknesses_seq.nextval, weakness_of, weakness_to);
  else
    DBMS_OUTPUT.put_line('add_magic_weakness: ERROR - ' || name_weakness_of || ' or ' || name_weakness_to ||
                         ' is not a valid magic type!');
  end if;
end;
/

BEGIN
  delete from rpg_magic_weaknesses;
  add_magic_weakness('fire', 'water');
  add_magic_weakness('water', 'earth');
  add_magic_weakness('earth', 'air');
  add_magic_weakness('air', 'fire');
END;
/

-- select * from RPG_MAGIC_WEAKNESSES;

-- =====================================================================================================================

-- item utilities:
-- there will be mainly 3 utilities: attack, defence and any

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

select generate_random_string(50)
from dual;

create or replace procedure generate_user is
  username_list arr_varchar2 := arr_varchar2('tachyon', 'ml997', 'lamp');

  username varchar2(200);
  password varchar2(200);
  email varchar2(200);
BEGIN
  username := generate_random_string(DBMS_RANDOM.value(5, 20));
  password := generate_random_string(DBMS_RANDOM.value(5, 20));
  email := generate_email();

  insert into RPG_USERS
  values (rpg_users_seq.nextval, username, password, email);
END;

begin
  for i in 0..25000 loop
    generate_user();
  end loop;
end;

select * from RPG_USERS;

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
  for i in 0..100000 loop
    generate_friendships();
  end loop;
end;

select count(*)
from RPG_FRIENDS;

select *
from RPG_FRIENDS;

