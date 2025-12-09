--   Remove an occurrence from the database
delete from public.occurrence as o
where o.id = $1
returning o.id;
