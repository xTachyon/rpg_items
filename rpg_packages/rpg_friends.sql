create or replace package rpg_friends_pk as
  procedure get_friends(in_user_id in rpg_users.USER_ID%type, out_friends out FRIENDS_LIST);
  procedure delete_friend(in_friend_id in rpg_users.USER_ID%type, in_user_id in rpg_users.USER_ID%type);
  procedure add_friend(in_user_id in rpg_users.USER_ID%type, in_friend_name in rpg_users.username%type);
  function simulate_attack(in_stats1 in stats_report, effects1 in out character_effects,
                    in_stats2 in stats_report, effects2 in out character_effects) return clob;
  function battle_characters(in_character_id1 in number,in_character_id2 in number) return clob;
end;

create or replace package body rpg_friends_pk as

procedure get_friends(in_user_id in rpg_users.USER_ID%type, out_friends out FRIENDS_LIST) as
  aux_friends FRIENDS_LIST;
  begin
    select friend_record(u.USER_ID, u.USERNAME)
      bulk collect into out_friends
    from RPG_FRIENDS f join RPG_USERS u on f.USER_ID1 = u.USER_ID
    where f.USER_ID2 = in_user_id;
    select friend_record(u.USER_ID, u.USERNAME)
      bulk collect into aux_friends
    from RPG_FRIENDS f join RPG_USERS u on f.USER_ID2 = u.USER_ID
    where f.USER_ID1 = in_user_id;
    out_friends := out_friends multiset union distinct aux_friends;
    exception when no_data_found then
    out_friends := null;
  end;

procedure delete_friend(in_friend_id in rpg_users.USER_ID%type, in_user_id in rpg_users.USER_ID%type) as
begin
  delete from RPG_FRIENDS where (USER_ID1 = in_friend_id and USER_ID2 = in_user_id) or (USER_ID2 = in_friend_id and USER_ID1 = in_user_id);
end;

procedure add_friend(in_user_id in rpg_users.USER_ID%type, in_friend_name in rpg_users.username%type) as
  p_count number;
  p_friend_id number;
begin
  select count(*) into p_count from RPG_USERS where lower(USERNAME) = lower(in_friend_name);
  if(p_count = 0) then
    raise_application_error(-20008,'Username inexistent');
  end if;
  select user_id into p_friend_id from RPG_USERS where lower(USERNAME) = lower(in_friend_name);
  select count(*) into p_count from RPG_FRIENDS where (in_user_id = USER_ID1 and p_friend_id = USER_ID2) or
                                                      (in_user_id = USER_ID2 and p_friend_id = USER_ID1);
  if( p_count <> 0 ) then
    raise_application_error(-20009,'Sunteti deja prieten cu acest utilizator');
  end if;

  insert into RPG_FRIENDS(FRIENDSHIP_ID,USER_ID1,USER_ID2) values (RPG_FRIENDS_SEQ.nextval,in_user_id,p_friend_id);
end;

function simulate_attack(in_stats1 in stats_report, effects1 in out character_effects,
                    in_stats2 in stats_report, effects2 in out character_effects)
return clob is
  p_damage number := 0;
  p_multiplier number :=1;
  p_exst number;
  output clob := '';
begin
  if(effects1.STUN_DURATION <= 0)then
    p_damage := in_stats1.ATTACK_DAMAGE;
    if(in_stats1.MAGIC_TYPES is not null and in_stats1.MAGIC_TYPES.COUNT > 0 and
       in_stats2.MAGIC_TYPES is not null and in_stats2.MAGIC_TYPES.COUNT > 0) then
        for i in in_stats1.MAGIC_TYPES.first .. in_stats1.MAGIC_TYPES.LAST loop
          for j in in_stats2.MAGIC_TYPES.first .. in_stats2.MAGIC_TYPES.LAST loop
            select case
               when exists(select 'x' from RPG_MAGIC_WEAKNESSES_VIEW
                  where "Strong_Magic_ID" = in_stats1.MAGIC_TYPES(i) and "Weak_Magic_ID" = in_stats2.MAGIC_TYPES(j))
               then 1
               else 0
             end  into p_exst
            from dual;
            if(p_exst = 1) then
                p_multiplier := p_multiplier + 0.5;
            end if;
          end loop;
        end loop;
    end if;


    if(dbms_random.value(0,1) < in_stats2.PARRY_CHANCE ) then
      output := output || chr(13)||chr(10) || 'My attack has been blocked!';
    else
      p_damage := p_damage * p_multiplier;
      if(dbms_random.value(0,1) < in_stats1.ENRAGE and effects1.CHARACTER_HEALTH < in_stats1.CHARACTER_HEALTH) then
        p_damage := p_damage + p_damage * in_stats1.ENRAGE;
        output := output || chr(13)||chr(10) || 'I am enraged!';
      end if;
      if(dbms_random.value(0,1) < in_stats1.CRITICAL_CHANCE) then
        p_damage := p_damage + p_damage * in_stats1.CRITICAL_CHANCE;
        output := output || chr(13)||chr(10) || 'Critical hit!';
      end if;
      if(dbms_random.value(0,1) < in_stats1.DOUBLE_HIT_CHANCE) then
        p_damage := p_damage*2;
        output := output || chr(13)||chr(10) || 'Double hit!';
      end if;

      effects2.CHARACTER_HEALTH := effects2.CHARACTER_HEALTH - in_stats1.ARMOR_BREAKING_DAMAGE;
      if(effects2.ARMOR <= 0 or dbms_random.value(0,1) < in_stats1.DEFENCE_BREAKING_CHANCE ) then
        effects2.CHARACTER_HEALTH := effects2.CHARACTER_HEALTH - p_damage;
        if(in_stats2.DAMAGE_REFLECTION > 0) then
          effects1.CHARACTER_HEALTH := effects1.CHARACTER_HEALTH - p_damage * in_stats2.DAMAGE_REFLECTION;
          output := output || chr(13)||chr(10) || 'My enemy reflected  ' || p_damage * in_stats2.DAMAGE_REFLECTION || ' points of damage back to me!';
        end if;
      else
        effects2.ARMOR := effects2.ARMOR - p_damage;
      end if;

      if(dbms_random.value(0,1) < in_stats1.STUN_CHANCE - in_stats2.STUN_CHANCE_REDUCTION) then
        effects2.STUN_DURATION := effects2.STUN_DURATION + in_stats1.STUN_DURATION;
        output := output || chr(13)||chr(10) || 'I succesfully stunned my enemy for ' || in_stats1.STUN_DURATION || ' turns!';
      end if;
      if(dbms_random.value(0,1) < in_stats1.BLEEDING_CHANCE - in_stats2.BLEEDING_CHANCE_REDUCTION) then
        effects2.BLEEDING_DURATION := effects2.BLEEDING_DURATION + in_stats1.BLEEDING_DURATION;
        output := output || chr(13)||chr(10) || 'My enemy is bleeding now for the next ' || in_stats1.BLEEDING_DURATION || ' turns!';
      end if;
      if(dbms_random.value(0,1) < in_stats1.POISON_CHANCE - in_stats2.POISON_CHANCE_REDUCTION) then
        effects2.POISON_DURATION := effects2.POISON_DURATION + in_stats1.POISON_DURATION;
        output := output || chr(13)||chr(10) || 'I succesfully poisoned my enemy for ' || in_stats1.POISON_DURATION || ' turns!';
      end if;
      output := output || chr(13)||chr(10) || 'I succesfully attacked my enemy for ' || p_damage || ' points of damage!';
    end if;
  else
    output := output || chr(13)||chr(10) || 'Still in stun for ' || effects1.STUN_DURATION || ' more turns!';
  end if;

  if(effects1.STUN_DURATION > 0) then
    effects1.STUN_DURATION := effects1.STUN_DURATION -1;
  end if;
   if(effects1.BLEEDING_DURATION > 0) then
    effects1.BLEEDING_DURATION := effects1.BLEEDING_DURATION -1;
  end if;
   if(effects1.POISON_DURATION > 0) then
    effects1.POISON_DURATION := effects1.POISON_DURATION -1;
  end if;
  if(effects1.ARMOR > 0 and in_stats1.ARMOR_REGEN > 0 ) then
    effects1.ARMOR := effects1.ARMOR + in_stats1.ARMOR * in_stats1.ARMOR_REGEN;
    if(in_stats1.ARMOR < effects1.ARMOR ) then
      effects1.ARMOR := in_stats1.ARMOR;
    end if;
    output := output || chr(13)||chr(10) || 'Regenerated '|| in_stats1.ARMOR * in_stats1.ARMOR_REGEN || ' points of armor!';
  end if;
  if(effects1.CHARACTER_HEALTH > 0 and in_stats1.HEALTH_REGEN > 0 ) then
    effects1.CHARACTER_HEALTH := effects1.CHARACTER_HEALTH +  in_stats1.CHARACTER_HEALTH * in_stats1.HEALTH_REGEN;
    if(in_stats1.CHARACTER_HEALTH < effects1.CHARACTER_HEALTH ) then
      effects1.CHARACTER_HEALTH := in_stats1.CHARACTER_HEALTH;
    end if;
    output := output || chr(13)||chr(10) || 'Regenerated '|| in_stats1.CHARACTER_HEALTH * in_stats1.HEALTH_REGEN || ' points of health!';
  end if;
  if(effects1.POISON_DURATION > 0) then
    effects1.POISON_DURATION := effects1.POISON_DURATION - 1;
    effects1.CHARACTER_HEALTH := effects1.CHARACTER_HEALTH - in_stats2.POISONOUS_DAMAGE;
    output := output || chr(13)||chr(10) || 'Just took '|| in_stats2.POISONOUS_DAMAGE ||' points of damage from poison!';
  end if;
  if(effects1.BLEEDING_DURATION > 0) then
    effects1.BLEEDING_DURATION := effects1.BLEEDING_DURATION - 1;
    effects1.CHARACTER_HEALTH := effects1.CHARACTER_HEALTH - in_stats2.BLEEDING_DAMAGE;
    output := output || chr(13)||chr(10) || 'Just took '|| in_stats2.BLEEDING_DAMAGE ||' points of damage from bleeding!';
  end if;
  return output;
end;

function battle_characters(in_character_id1 in number,in_character_id2 in number)
 return clob is
  stats1 stats_report;
  stats2 stats_report;
  effects1 character_effects;
  effects2 character_effects;
  output clob := '';
begin
  stats1 := rpg_character.get_stats_report_for_character(in_character_id1);
  stats2 := rpg_character.get_stats_report_for_character(in_character_id2);
  effects1 := character_effects(stats1.CHARACTER_HEALTH,stats1.ARMOR,0,0,0);
  effects2 := character_effects(stats2.CHARACTER_HEALTH,stats2.ARMOR,0,0,0);
  loop
    exit when effects1.CHARACTER_HEALTH <= 0 or effects2.CHARACTER_HEALTH <=0;
    output := output || chr(13)||chr(10) || 'Character '|| in_character_id1 || ' turn to attack (Current health ='||
              effects1.CHARACTER_HEALTH ||' Current armor = '||effects1.ARMOR||'):';
    output := output || simulate_attack(stats1,effects1,stats2,effects2);
    DBMS_OUTPUT.PUT_LINE(effects2.CHARACTER_HEALTH);
    exit when effects1.CHARACTER_HEALTH <= 0 or effects2.CHARACTER_HEALTH <=0;
    output := output || chr(13)||chr(10) || 'Character '|| in_character_id2 || ' turn to attack (Current health ='||
              effects2.CHARACTER_HEALTH ||' Current armor = '||effects2.ARMOR||'):';
    output := output || simulate_attack(stats2,effects2,stats1,effects1);
  end loop;
  if(effects1.CHARACTER_HEALTH > 0) then
    output := output || chr(13)||chr(10) || 'Character '|| in_character_id1 || ' won!';
  else
    output := output || chr(13)||chr(10) || 'Character '|| in_character_id2 || ' won!';
  end if;
  return output;
end;

end;