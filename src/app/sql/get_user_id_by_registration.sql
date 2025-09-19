SELECT u.id
FROM user_account AS u
WHERE u.registration = $1;
