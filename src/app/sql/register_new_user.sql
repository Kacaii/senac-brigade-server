INSERT INTO user_account (
    full_name,
    password_hash,
    registration,
    email
) VALUES (
    $1,
    $2,
    $3,
    $4
)
