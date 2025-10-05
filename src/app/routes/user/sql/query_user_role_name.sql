-- 󰀖  Find user access level
SELECT ur.role_name FROM
    public.user_account AS u
INNER JOIN public.user_role AS ur
    ON u.role_id = ur.id
WHERE u.id = $1;
