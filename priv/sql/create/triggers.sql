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
    AND b.members_id IS NOT NULL
    AND ARRAY_LENGTH(b.members_id, 1) > 0;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_insert_brigade_membership
AFTER INSERT ON public.brigade
FOR EACH ROW
EXECUTE FUNCTION public.dump_brigade_members();

--   Register all participants of a occurrence
CREATE OR REPLACE FUNCTION public.dump_occurrence_participants()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.occurrence_brigade_member (occurrence_id, user_id)
    SELECT NEW.id, UNNEST(b.members_id)
        FROM public.occurrence AS o
    JOIN public.brigade AS b
        on o.brigade_id = b.id
    WHERE o.id = NEW.id
    AND b.members_id IS NOT NULL
    AND ARRAY_LENGTH(b.members_id, 1) > 0;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_dump_occurrence_participants
AFTER INSERT ON public.occurrence
FOR EACH ROW
EXECUTE FUNCTION public.dump_occurrence_participants();
