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

/* jobs */
create or replace procedure delete_characters_job as
  begin
    delete from RPG_CHARACTERS where DELETED_AT is not null and ceil(trunc(DELETED_AT + 3) - sysdate) <= 0;
    commit;
end;

BEGIN
 DBMS_SCHEDULER.CREATE_JOB (
   job_name => 'delete_characters_schedule',
   job_type => 'STORED_PROCEDURE',
   job_action => 'DELETE_CHARACTERS_JOB',
   start_date =>  TO_DATE('23-05-2019 21:00','DD-MM-YYYY HH24:MI'),
   repeat_interval => 'FREQ=HOURLY; INTERVAL=1',
   enabled  =>  TRUE);
END;

begin
  DBMS_SCHEDULER.DROP_JOB(job_name => 'delete_characters_schedule');
end;

create or replace procedure delete_items_job as
begin
    delete from RPG_items where EXPIRATION_DATE is not null and EXPIRATION_DATE < sysdate;
    commit;
end;

BEGIN
 DBMS_SCHEDULER.CREATE_JOB (
   job_name => 'delete_items_schedule',
   job_type => 'STORED_PROCEDURE',
   job_action => 'DELETE_ITEMS_JOB',
   start_date =>  TO_DATE('23-05-2019 21:00','DD-MM-YYYY HH24:MI'),
   repeat_interval => 'FREQ=HOURLY; INTERVAL=1',
   enabled  =>  TRUE);
END;

begin
  DBMS_SCHEDULER.DROP_JOB(job_name => 'delete_items_schedule');
end;

select * from ALL_SCHEDULER_JOBS ;

/* types */

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
-- stats manager

create type ARR_NUMBER as table of NUMBER;
create or replace type stats_report is object (
  character_health number,
  user_gold number,
  attack_damage number,
  critical_damage number,
  critical_chance number,
  bleeding_damage number,
  bleeding_chance number,
  bleeding_duration number,
  poisonous_damage number,
  poison_chance number,
  poison_duration number,
  stun_chance number,
  stun_duration number,
  double_hit_chance number,
  armor_breaking_damage number,
  defence_breaking_chance number,
  enrage number,
  armor number,
  health number,
  health_regen number,
  armor_regen number,
  parry_chance number,
  stun_chance_reduction number,
  bleeding_chance_reduction number,
  poison_chance_reduction number,
  damage_reflection number,
  magic_types ARR_NUMBER
);
/
create or replace type friend_record is object (
  friend_id number,
  friend_name varchar2(200),
  map member function get_id return number
);
/
CREATE TYPE BODY friend_record AS
   MAP MEMBER FUNCTION get_id RETURN NUMBER IS
   BEGIN
      RETURN friend_id;
   END get_id;
END;
/
create or replace type FRIENDS_LIST is table of friend_record;
/
drop type FRIENDS_LIST;
/
create or replace type character_effects is object (
  character_health number,
  armor number,
  bleeding_duration number,
  poison_duration number,
  stun_duration number
);