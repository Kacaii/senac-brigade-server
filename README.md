# 👩‍🚒 SENAC Brigade

## Architecture

![Backend Architecture](assets/backend_architecture.png)

## Routes

| Route            | Description                 | Expected    |
| ---------------- | --------------------------- | ----------- |
| /api/user/signup | Register a new user account | POST (Form) |
| /api/brigade/:id | List brigade members        | GET         |

## Entity RelationShip Diagram

```mermaid
---
title: SENAC Brigade
---
erDiagram

    user_role {
        UUID id PK
        TEXT name
        TEXT description
    }

    user_account }|--|| user_role : is
    user_account {
        UUID id PK
        INTEGER role_id FK
        TEXT full_name
        TEXT password_hash
        TEXT registration
        TEXT phone
        TEXT email UK
        BOOLEAN is_active
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    brigade {
        UUID id PK
        TEXT name
        TEXT description
        BOOLEAN is_active
    }

    brigade_membership }o--o{ user_account : is_member_of
    brigade_membership }o--o{ brigade : is_part_of
    brigade_membership {
        UUID id PK
        UUID user_id FK
        UUID group_id FK
    }

    occurrence_type |o--o{ occurrence_type : subtype_of
    occurrence_type {
        UUID id PK
        UUID parent_type FK
        TEXT name UK
        TEXT description
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    occurrence }|--|| user_account : submit
    occurrence }|--|| occurrence_type : is
    occurrence {
        UUID id PK
        UUID applicant_id FK
        UUID type_id FK
        TEXT description
        POINT location
        TEXT reference_point
        NUMERIC(2) loss_percentage
        TIMESTAMP created_at
        TIMESTAMP updated_at
        TIMESTAMP resolved_at
    }
```
