# 👩‍🚒 SENAC Brigade

## Architecture

![Backend Architecture](assets/backend_architecture.png)

## Routes

| Route               | Description                 | Expected    |
| ------------------- | --------------------------- | ----------- |
| /cadastrar          | Register a new user account | POST (Form) |
| /listar_membros/:id | List brigade members        | GET         |

## Entity RelationShip Diagram

```mermaid
---
title: SENAC Brigade
---
erDiagram

    user_role {
        UUID id PK
        VARCHAR(255) name
        TEXT description
    }

    user_account }|--|| user_role : is
    user_account {
        UUID id PK
        INTEGER role_id FK
        VARCHAR(255) email UK
        VARCHAR(255) full_name
        TEXT password_hash
        VARCHAR(255) registration
        VARCHAR(255) phone
        BOOLEAN is_active
    }

     brigade {
        UUID id PK
        varchar(255) name
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

    ocurrence_type |o--o{ ocurrence_type : has_parent
    ocurrence_type {
        UUID id PK
        UUID parent_type FK
        VARCHAR(255) name UK
        TEXT description
        TIMESTAMP created_at
    }

    ocurrence }|--|| user_account : submit
    ocurrence }|--|| ocurrence_type : is
    ocurrence {
        UUID id PK
        UUID applicant_id FK
        UUID type_id FK
        TEXT description
        VARCHAR(255) address
        VARCHAR(255) reference_point
        NUMERIC(2) loss_percentage
        TIMESTAMP created_at
        TIMESTAMP updated_at
        TIMESTAMP resolved_at
    }
```
