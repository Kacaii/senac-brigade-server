--   Remove a brigade from the DataBase
delete from public.brigade as b
where b.id = $1
returning
    b.id,
    b.brigade_name;
