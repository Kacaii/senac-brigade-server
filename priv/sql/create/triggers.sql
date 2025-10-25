--   Sets default user notification preferences when inserting a new one
CREATE OR REPLACE FUNCTION public.set_default_notification_preferences()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_notification_preference (user_id, notification_type)
    VALUES
        (NEW.id, 'fire'),
        (NEW.id, 'emergency'),
        (NEW.id, 'traffic'),
        (NEW.id, 'other')
    ON CONFLICT (user_id, notification_type) DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER tgr_default_notification_preferences
AFTER INSERT ON public.user_account
FOR EACH ROW
EXECUTE FUNCTION public.set_default_notification_preferences();

--   Register all members of an brigade when creating a new one
CREATE OR REPLACE FUNCTION public.dump_brigade_members()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.members_id IS NOT NULL AND ARRAY_LENGTH(NEW.members_id, 1) > 0 THEN
        INSERT INTO public.brigade_membership (brigade_id, user_id)
        SELECT NEW.id, member_id
        FROM UNNEST(NEW.members_id) as member_id
        ON CONFLICT (brigade_id, user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER tgr_insert_brigade_membership
AFTER INSERT ON public.brigade
FOR EACH ROW
EXECUTE FUNCTION public.dump_brigade_members();

--   Register all participants of a occurrence
CREATE OR REPLACE FUNCTION public.dump_occurrence_participants()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO occurrence_brigade_member (occurrence_id, user_id)
    SELECT NEW.id, UNNEST(b.members_id) AS member_id
    FROM public.brigade AS b
    WHERE b.id = ANY(NEW.brigade_list)
    AND b.members_id IS NOT NULL
    ON CONFLICT (occurrence_id, user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER tgr_dump_occurrence_participants
AFTER INSERT ON public.occurrence
FOR EACH ROW
EXECUTE FUNCTION public.dump_occurrence_participants();
