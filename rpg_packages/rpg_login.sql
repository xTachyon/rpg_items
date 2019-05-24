create or replace package rpg_login as
  function user_login(in_username in rpg_users.username%type, in_password in rpg_users.password%type) return rpg_users.user_id%type;
end;

create or replace package body rpg_login as

function user_login(in_username in rpg_users.username%type, in_password in rpg_users.password%type)
return rpg_users.user_id%type is
  v_user_id rpg_users.user_id%type;
  counter number;
  mesaj varchar2(100);
  m_sql varchar2(2000);
begin
  DBMS_OUTPUT.PUT_LINE(in_password);
  m_sql := 'select USER_ID from RPG_USERS where '''||in_username||''' = USERNAME and '''|| in_password ||''' = PASSWORD';
  execute immediate m_sql into v_user_id ;
  return v_user_id;
  exception
  when no_data_found then
    SELECT COUNT(*) INTO counter FROM RPG_USERS WHERE USERNAME = in_username;
    IF counter = 0 THEN
      mesaj   := 'Utilizatorul ' || in_username || ' nu exista.';
    ELSE
      mesaj   := 'Parola gresita pentru utilizatorul ' || in_username || '.';
    END IF;
    raise_application_error (-20001, mesaj);
end;

end;

-- pt sql injection
-- select rpg_login.user_login('xppmgcxcavvcvsirosg','1''=''1'' or ''1') from dual;