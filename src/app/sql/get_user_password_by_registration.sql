SELECT u.password_hash
FROM user_account AS u
WHERE u.registration = $1;
