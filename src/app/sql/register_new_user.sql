INSERT INTO public.user_account (
    full_name,
    registration,
    phone,
    email,
    password_hash
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5
)
