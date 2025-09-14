SELECT
    u.full_name,
    u.registration
FROM user_account AS u
INNER JOIN brigade_membership AS bm ON u.id = bm.user_id
WHERE bm.brigade_id = $1 -- <- Brigade ID here
