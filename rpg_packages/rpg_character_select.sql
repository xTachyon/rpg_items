/* characters list */
create or replace package rpg_character_select as
  procedure get_characters(in_user_id in rpg_users.USER_ID%type, out_characters out character_list);
  procedure delete_character(in_character_id in rpg_characters.CHARACTER_ID%type);
  procedure restore_character(in_character_id in rpg_characters.CHARACTER_ID%type);
end;

create or replace package body rpg_character_select as

procedure get_characters(in_user_id in rpg_users.USER_ID%type, out_characters out character_list) as
  begin
    select character_list_record(CHARACTER_ID, name, floor(CHARACTER_LEVEL), trim(nvl(to_char(ceil(trunc(DELETED_AT + 3) - sysdate)),'inf')))
      bulk collect into out_characters
    from RPG_CHARACTERS c join RPG_USERS u on u.USER_ID = c.USER_ID
    where u.USER_ID = in_user_id;
  end;

procedure delete_character(in_character_id in rpg_characters.CHARACTER_ID%type) as
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

  procedure restore_character(in_character_id in rpg_characters.CHARACTER_ID%type) as
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

end;