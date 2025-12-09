begin;

-- 󱈤  TYPES --------------------------------------------------------------------

create type public.user_role_enum as enum (
    'admin',
    'analyst',
    'firefighter',
    'captain',
    'developer',
    'sargeant'
);

create type public.notification_type_enum as enum (
    'fire',
    'emergency',
    'traffic',
    'other'
);

create type public.occurrence_category_enum as enum (
    'medic_emergency',
    'fire',
    'traffic_accident',
    'other'
);

create type public.occurrence_subcategory_enum as enum (
    -- 󰋠  Medic Emergency,
    'heart_stop',
    'pre_hospital_care',
    'seizure',
    'serious_injury',
    'intoxication',

    --   Fire
    'residential',
    'comercial',
    'vegetation',
    'vehicle',

    --   Traffic Accident
    'collision',
    'run_over',
    'rollover',
    'motorcycle_crash',

    --   Other
    'tree_crash',
    'flood',
    'injured_animal'
);

create type occurrence_priority_enum as enum (
    'low',
    'medium',
    'high'
);

-- 󰓶  TABLES -------------------------------------------------------------------

create table if not exists public.user_account (
    id uuid default uuidv7(),
    user_role user_role_enum not null,
    full_name text not null,
    password_hash text not null,
    registration text unique not null,
    phone text unique default null,
    email text not null unique,
    is_active boolean not null default true,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    primary key (id)
);

create index if not exists idx_user_registration
on public.user_account (registration);


create table if not exists public.user_notification_preference (
    id uuid default uuidv7(),
    user_id uuid not null references public.user_account (id)
    on update cascade on delete cascade,
    notification_type notification_type_enum not null,
    enabled boolean not null default false,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    unique (user_id, notification_type),
    primary key (id)
);


create table if not exists public.brigade (
    id uuid default uuidv7(),
    leader_id uuid not null references public.user_account (id)
    on update cascade on delete cascade,
    vehicle_code text not null,
    brigade_name text not null,
    description text default null,
    is_active boolean not null default false,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    primary key (id)
);

create index if not exists idx_brigade_leader_id
on public.brigade (leader_id);


create table if not exists public.brigade_membership (
    id uuid default uuidv7(),
    brigade_id uuid not null references public.brigade (id)
    on update cascade on delete cascade,
    user_id uuid not null references public.user_account (id)
    on update cascade on delete cascade,
    unique (user_id, brigade_id),
    primary key (id)
);

create index if not exists idx_brigade_membership_user_id
on public.brigade_membership (user_id);

create index if not exists idx_brigade_membership_brigade_id
on public.brigade_membership (brigade_id);


create table if not exists public.occurrence (
    id uuid default uuidv7(),
    applicant_id uuid not null references public.user_account (id)
    on update cascade on delete cascade,
    occurrence_category occurrence_category_enum not null,
    occurrence_subcategory occurrence_subcategory_enum,
    priority occurrence_priority_enum not null,
    description text,
    occurrence_location float [],
    reference_point text,
    created_at timestamp not null default current_timestamp,
    arrived_at timestamp default null,
    updated_at timestamp not null default current_timestamp,
    resolved_at timestamp default null,
    primary key (id)
);

create index if not exists idx_occurrence_applicant_id
on public.occurrence (applicant_id);

create index if not exists idx_occurrence_created_at
on public.occurrence (created_at);


create table if not exists public.occurrence_brigade (
    id uuid default uuidv7(),
    occurrence_id uuid not null references public.occurrence (id)
    on update cascade on delete cascade,
    brigade_id uuid not null references public.brigade (id)
    on update cascade on delete cascade,
    unique (occurrence_id, brigade_id),
    primary key (id)
);

create index if not exists idx_occurrence_brigade_occurrence_id
on public.occurrence_brigade (occurrence_id);

create index if not exists idx_occurrence_brigade_brigade_id
on public.occurrence_brigade (brigade_id);

commit;
