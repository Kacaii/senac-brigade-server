--   Sets default user notification preferences when inserting a new one
create or replace function public.set_default_notification_preferences()
returns trigger
language plpgsql
as $$
begin
    insert into public.user_notification_preference (user_id, notification_type)
    values
        (new.id, 'fire'),
        (new.id, 'emergency'),
        (new.id, 'traffic'),
        (new.id, 'other')
    on conflict (user_id, notification_type) do nothing;

    return new;
end;
$$;

create or replace trigger tgr_default_notification_preferences
after insert on public.user_account
for each row
execute function public.set_default_notification_preferences();
