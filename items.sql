drop table rpg_users;

create table rpg_users (
  user_id number primary key,
  username varchar2(20) not null,
  password varchar2(50) not null,
  email varchar2(50) not null,
  created_at date not null
);

create sequence rpg_users_seq start with 1;

create or replace trigger rpg_users_trigger
before insert on rpg_users
for each row

  begin
    select rpg_users_seq.nextval
    into :new.user_id
    from dual;
  end;

drop table rpg_friends;

create table rpg_friends (
  friendship_id number primary key,
  user_id1 number not null,
  user_id2 number not null,
  constraint fk_friends_users1
    foreign key (user_id1)
    references rpg_users(user_id),
  constraint fk_friends_users2
    foreign key (user_id2)
    references rpg_users(user_id)
);

create table rpg_classes (
  class_id number primary key,
  class_name varchar2(50) not null
);

drop table rpg_characters;

create table rpg_characters (
  character_id number primary key,
  user_id number not null,
  name varchar(20) not null,
--   created_at date not null,
  character_level number not null,
  class_id number not null,
  gold number not null,
  constraint fk_characters_users
    foreign key (user_id)
    references rpg_users(user_id),
  constraint fk_characters_class
    foreign key (class_id)
    references rpg_classes(class_id)
);

create table rpg_item_types (
  type_id number primary key,
  type_name varchar2(200) not null
);

drop table rpg_item_rarity;

create table rpg_item_rarity (
  rarity_id number primary key,
  rarity_name varchar2(200) not null,
  rarity_color varchar2(200) not null
);

create table rpg_magic_types (
  magic_id number primary key,
  magic_name varchar2(200) not null
);

drop table rpg_items;

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
  constraint fk_items_users
    foreign key (owner_id)
    references rpg_users(user_id),
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

create table rpg_stat_types (
  type_id number primary key,
  name varchar2(200) not null
);

drop table rpg_stats;

create table rpg_stats (
  stat_id number primary key,
  item_id number not null,
  type number not null,
  value number not null,
  constraint fk_stats_items
    foreign key (item_id)
    references rpg_items(item_id),
  constraint fk_stats_stat_types
    foreign key (type)
    references rpg_stat_types(type_id)
);

create table rpg_magic_weaknesses (
  weakness_id number primary key,
  weakness_of number not null,
  weakness_to number not null,
  constraint fk_magic_weak_magic_types1
    foreign key (weakness_of)
    references rpg_magic_types(magic_id),
  constraint fk_magic_weak_magic_types2
    foreign key (weakness_to)
    references rpg_magic_types(magic_id)
);