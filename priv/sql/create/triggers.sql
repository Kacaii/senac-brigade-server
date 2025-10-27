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
