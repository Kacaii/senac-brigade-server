--   Sets default user notification preferences when inserting a new one
CREATE OR REPLACE FUNCTION public.set_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notification_preference
        (user_id, notification_type)
    VALUES
        (NEW.id, 'fire'),
        (NEW.id, 'emergency'),
        (NEW.id, 'traffic'),
        (NEW.id, 'other');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_default_notification_preferences
AFTER INSERT ON public.user_account
FOR EACH ROW
EXECUTE FUNCTION public.set_default_notification_preferences();

--   Register all members of an brigade when creating a new one
CREATE OR REPLACE FUNCTION public.dump_brigade_members()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.brigade_membership (brigade_id, user_id)
    SELECT NEW.id, UNNEST(members_id)
    FROM public.brigade AS b
    WHERE b.id = NEW.id
    AND members_id IS NOT NULL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_insert_brigade_membership
AFTER INSERT ON public.brigade
FOR EACH ROW
EXECUTE FUNCTION public.dump_brigade_members();
