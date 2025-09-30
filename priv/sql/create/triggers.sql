DROP FUNCTION IF EXISTS public.dump_occurrence_participants;
DROP TRIGGER IF EXISTS tgr_insert_member_participation ON occurrence;

-- 
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
