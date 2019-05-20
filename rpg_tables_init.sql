-- Made by Damian Andrei and Lipan Radu-Matei, A1

DROP TABLE rpg_users CASCADE CONSTRAINTS
/
DROP TABLE rpg_friends CASCADE CONSTRAINTS
/
DROP TABLE rpg_characters CASCADE CONSTRAINTS
/
DROP TABLE rpg_items CASCADE CONSTRAINTS
/
DROP TABLE rpg_item_utilities CASCADE CONSTRAINTS
/
DROP TABLE rpg_item_types CASCADE CONSTRAINTS
/
DROP TABLE rpg_item_rarity CASCADE CONSTRAINTS
/
DROP TABLE rpg_magic_types CASCADE CONSTRAINTS
/
DROP TABLE rpg_stat_types CASCADE CONSTRAINTS
/
DROP TABLE rpg_item_stats CASCADE CONSTRAINTS
/
DROP TABLE rpg_magic_weaknesses CASCADE CONSTRAINTS
/


create table rpg_users (
  user_id number primary key,
  username varchar2(20) not null unique,
  password varchar2(50) not null,
  email varchar2(50) not null unique
);
/

create table rpg_friends (
  friendship_id number primary key,
  user_id1 number not null,
  user_id2 number not null,
  constraint fk_friends_users1
    foreign key (user_id1)
    references rpg_users(user_id),
  constraint fk_friends_users2
    foreign key (user_id2)
    references rpg_users(user_id),
  constraint no_duplicates_friends unique (user_id1, user_id2)
);
/

create table rpg_characters (
  character_id number primary key,
  user_id number not null,
  name varchar(20) not null,
  character_level number not null,
  gold number not null,
  deleted_at date,
  constraint fk_characters_users
    foreign key (user_id)
    references rpg_users(user_id)
);
/

create table rpg_item_utilities (
  utility_id number primary key,
  utility_name varchar2(200) not null
);
/

create table rpg_item_types (
  type_id number primary key,
  utility_id number not null,
  type_name varchar2(200) not null,
  constraint fk_item_types_utility
    foreign key (utility_id)
    references rpg_item_utilities(utility_id)
);
/

create table rpg_item_rarity (
  rarity_id number primary key,
  rarity_name varchar2(200) not null,
  rarity_color varchar2(200) not null,
  stats_number number
);
/

create table rpg_magic_types (
  magic_id number primary key,
  magic_name varchar2(200) not null
);
/

create table rpg_items (
  item_id number primary key,
  owner_id number not null,
  base_level number not null,
  current_durability number not null,
  maximum_durability number not null,
  expiration_date date,
  item_type number not null,
  item_rarity number not null,
  item_magic_type number not null,
  is_equipped number(1) default 0,
  constraint fk_items_characters
    foreign key (owner_id)
    references rpg_characters(character_id),
  constraint fk_items_items_type
    foreign key (item_type)
    references rpg_item_types(type_id),
  constraint fk_items_rarity
    foreign key (item_rarity)
    references rpg_item_rarity(rarity_id),
  constraint fk_items_magic_types
    foreign key (item_magic_type)
    references rpg_magic_types(magic_id)
);
/

create table rpg_stat_types (
  type_id number primary key,
  utility_id number not null,
  name varchar2(200) not null unique,
  min_base_value number,
  max_base_value number,
  constraint fk_stat_types_utility
    foreign key (utility_id)
    references rpg_item_utilities(utility_id)
);
/

create table rpg_item_stats (
  item_id number not null,
  type_id number not null,
  value number not null,
  constraint pk_item_stats
    primary key (item_id,type_id),
  constraint fk_item_stats_items
    foreign key (item_id)
    references rpg_items(item_id),
  constraint fk_item_stats_stat_types
    foreign key (type_id)
    references rpg_stat_types(type_id)
);
/

create table rpg_magic_weaknesses (
  weakness_id number primary key,
  weakness_of number not null,
  weakness_to number not null,
  constraint fk_magic_weak_magic_types1
    foreign key (weakness_of)
    references rpg_magic_types(magic_id),
  constraint fk_magic_weak_magic_types2
    foreign key (weakness_to)
    references rpg_magic_types(magic_id),
  constraint no_duplicates_magic_weaknesses unique (weakness_of, weakness_to)
);
/

-- sequences for the ids of the main tables
drop sequence rpg_users_seq;
/
drop sequence rpg_friends_seq;
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
drop sequence rpg_magic_weaknesses_seq;
/
drop sequence rpg_item_stats_req;
/

create sequence rpg_users_seq start with 1;
/
create sequence rpg_friends_seq start with 1;
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
create sequence rpg_magic_weaknesses_seq start with 1;
/
create sequence rpg_item_stats_req start with 1;


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
  -- getting the utility ids
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

-- =====================================================================================================================

-- users, friends and characters:

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
/

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
/

-- select generate_email()
-- from dual;
/

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
/
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
  for i in 1..100000 loop
    generate_friendships();
  end loop;
end;
/
-- select count(*)
-- from RPG_FRIENDS;
--
-- select *
-- from RPG_FRIENDS;

create or replace procedure generate_characters is
  cursor c is select USER_ID from RPG_USERS;

  number_characters number;
  name varchar2(200);
  character_level number;
  gold number;
BEGIN
  for row in c loop
    number_characters := DBMS_RANDOM.value(2, 7);
    for i in 0..number_characters loop
      name := generate_random_string(DBMS_RANDOM.value(15, 20));
      character_level := DBMS_RANDOM.value(1, 100);
      gold := DBMS_RANDOM.value(1, 342512);

      insert into RPG_CHARACTERS
      values(RPG_CHARACTERS_SEQ.nextval, row.USER_ID, name, character_level, gold, null);
    end loop;
  end loop;
END;

begin
  generate_characters();
end;
/

-- =====================================================================================================================

-- items and item stats:
drop sequence RPG_ITEMS_SEQ;
/
create sequence RPG_ITEMS_SEQ start with 1;
/
drop sequence RPG_ITEM_STATS_SEQ;
/
create sequence RPG_ITEM_STATS_SEQ start with 1;
/

create or replace procedure generate_random_item(p_owner_id in rpg_characters.character_id%type) as
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
begin
  -- random item data without the stats
  p_base_level := trunc(DBMS_RANDOM.value(1,101));
  p_item_type := trunc(DBMS_RANDOM.value(1, rpg_item_types_seq.currval + 1));
  p_item_rarity := trunc(DBMS_RANDOM.value(1, rpg_item_rarity_seq.currval + 1));
  p_item_magic_type := trunc(DBMS_RANDOM.value(1, rpg_magic_types_seq.currval + 1));
  if ( DBMS_RANDOM.value(0,1) <= 0.9 ) then
    p_expiration_date := sysdate + trunc(DBMS_RANDOM.value(1,31));
  else
    p_expiration_date := null;
  end if;
  p_durability := 10 * (p_base_level + trunc(DBMS_RANDOM.value(1,10)));

  insert into RPG_ITEMS values (rpg_items_seq.nextval,p_owner_id,p_base_level,p_durability,p_durability,p_expiration_date,p_item_type,
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
end;
/

-- insert 5-10 items for every person
declare
 p_num_items number;
 cursor characters_cursor is select CHARACTER_ID from RPG_CHARACTERS;
 p_row_num number:=0;
begin
 for character_row in characters_cursor loop
   p_num_items := trunc(DBMS_RANDOM.value(5,10));
   for i in 1.. p_num_items loop
      generate_random_item(character_row.CHARACTER_ID);
    end loop;
    p_row_num := p_row_num + p_num_items;
    if mod(p_row_num,100000) < 11 then
        COMMIT ;
      end if;
  end loop;
end; -- ~ 6 min
/

-- begin
--   generate_random_item(1);
-- end;
--
-- select count(*) from RPG_CHARACTERS;
-- select count(*) from rpg_items; -- ~ 1 mil
-- select count(*) from RPG_ITEM_STATS; -- ~ 5 mil
-- select UTILITY_ID, count(*) from rpg_items join RPG_ITEM_TYPES on RPG_ITEMS.ITEM_TYPE = RPG_ITEM_TYPES.TYPE_ID group by UTILITY_ID;
-- select rpg_item_stats.*, NAME, UTILITY_ID from rpg_item_stats join RPG_STAT_TYPES on RPG_ITEM_STATS.TYPE_ID = RPG_STAT_TYPES.TYPE_ID
-- where ITEM_ID = &item_id;


-- the indexes we plan to use
create index RPG_ITEM_STATS_ITEM_INDEX on RPG_ITEM_STATS(item_id);
/
drop index RPG_ITEM_STATS_ITEM_INDEX;
/
create index RPG_ITEMS_OWNER_INDEX on RPG_ITEMS(owner_id);
/
drop index RPG_ITEMS_OWNER_INDEX;
/
create index RPG_CHARACTERS_USER_INDEX on rpg_characters(user_id);
/
drop index RPG_CHARACTERS_USER_INDEX;
/

-- select rpg_item_stats.*
-- from RPG_ITEMS join rpg_item_stats on rpg_items.item_id = rpg_item_stats.item_id
--   join rpg_characters on rpg_items.owner_id = rpg_characters.character_id
--   join rpg_users on rpg_characters.user_id = rpg_users.user_id
-- where rpg_users.user_id = &user;


-- table views for human readability

create or replace view rpg_items_view as
select item_id,owner_id,base_level,current_durability,maximum_durability,expiration_date,type_name,utility_name,rarity_name,rarity_color,magic_name,is_equipped
from rpg_items join rpg_item_types on rpg_items.item_type = rpg_item_types.type_id
  join rpg_item_utilities on rpg_item_types.utility_id = rpg_item_utilities.utility_id
  join rpg_item_rarity on rpg_items.item_rarity = rpg_item_rarity.rarity_id
  join rpg_magic_types on rpg_items.item_magic_type = rpg_magic_types.magic_id;

-- select * from rpg_items_view;

create or replace  view rpg_stats_view as
select item_id, rpg_item_stats.type_id, name, rpg_item_utilities.utility_id, utility_name, rpg_item_stats.value
from rpg_item_stats join rpg_stat_types on rpg_item_stats.type_id = rpg_stat_types.type_id
  join rpg_item_utilities on rpg_stat_types.utility_id = rpg_item_utilities.utility_id;

select * from rpg_items_view join rpg_stats_view on rpg_items_view.item_id = rpg_stats_view.item_id;

create or replace view rpg_friends_view as
select ru1.user_id as "User_ID1",ru1.username as "User1", ru2.user_id as "User_ID2", ru2.username as "User2"
from rpg_users ru1 join rpg_friends rf on ru1.user_id = rf.user_id1
  join rpg_users ru2 on ru2.user_id = rf.user_id2;

-- select * from rpg_friends_view;

create or replace view rpg_magic_weaknesses_view as
select rmt1.magic_name as "Weak_Magic", rmt1.magic_id as "Weak_Magic_ID", rmt2.magic_name as "Strong_Magic", rmt1.magic_id as "Strong_Magic_ID"
from rpg_magic_types rmt1 join rpg_magic_weaknesses rmw on rmt1.magic_id = rmw.weakness_of
  join rpg_magic_types rmt2 on rmt2.magic_id = rmw.WEAKNESS_TO;

-- select * from rpg_magic_weaknesses_view;