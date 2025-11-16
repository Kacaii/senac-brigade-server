-- 󰀖  Find user access level
SELECT u.user_role
FROM
    public.user_account AS u
WHERE u.id = $1;
