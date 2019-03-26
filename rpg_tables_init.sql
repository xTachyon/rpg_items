DROP TABLE rpg_users CASCADE CONSTRAINTS
/
DROP TABLE rpg_friends CASCADE CONSTRAINTS
/
DROP TABLE rpg_classes CASCADE CONSTRAINTS
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
DROP TABLE rpg_class_stats CASCADE CONSTRAINTS
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

create table rpg_classes (
  class_id number primary key,
  class_name varchar2(50) not null
);
/

create table rpg_characters (
  character_id number primary key,
  user_id number not null,
  name varchar(20) not null,
  character_level number not null,
  class_id number not null,
  gold number not null,
  deleted_at date,
  constraint fk_characters_users
    foreign key (user_id)
    references rpg_users(user_id),
  constraint fk_characters_class
    foreign key (class_id)
    references rpg_classes(class_id)
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
  stat_id number primary key,
  item_id number not null,
  type_id number not null,
  value number not null,
  constraint fk_item_stats_items
    foreign key (item_id)
    references rpg_items(item_id),
  constraint fk_item_stats_stat_types
    foreign key (type_id)
    references rpg_stat_types(type_id)
);
/

create table rpg_class_stats (
  stat_id number primary key,
  class_id number not null,
  type_id number not null,
  value number not null,
  constraint fk_class_stats_classes
    foreign key (class_id)
    references rpg_classes(class_id),
  constraint fk_class_stats_stat_types
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


/*
create sequence rpg_users_seq start with 1;

create or replace trigger rpg_users_trigger
before insert on rpg_users
for each row

  begin
    select rpg_users_seq.nextval
    into :new.user_id
    from dual;
  end;
*/