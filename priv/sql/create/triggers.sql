--   Register all participants of an occurrence
CREATE OR REPLACE FUNCTION public.dump_occurrence_participants()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.occurrence_brigade_member (brigade_id, user_id)
    SELECT NEW.id, unnest(participants_id)
    FROM public.occurrence AS oc
    WHERE id = NEW.id
    AND participants_id IS NOT NULL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_insert_member_participation
AFTER INSERT ON public.occurrence
FOR EACH ROW
EXECUTE FUNCTION public.dump_occurrence_participants();

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
