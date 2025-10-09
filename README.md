<!-- markdownlint-disable  MD013 -->

# 👩‍🚒 SENAC Brigade

## Architecture

![Backend Architecture](assets/backend_architecture.png)

## Routes

| Route                          | Description                                        | Method      |
| ------------------------------ | -------------------------------------------------- | ----------- |
| /admin/signup                  | Register a new user account                        | POST (Form) |
| /user/login                    | Login with your user account                       | POST (Form) |
| /user/profile                  | Retrieve data about the authenticated user         | GET         |
| /user/roles                    | Get a list of all available roles                  | GET         |
| /user/{{id}}/occurrences       | Find all occurrences applied by this user          | GET         |
| /user/{{id}}/crew_members      | List fellow brigade members of this user           | GET         |
| /user/notification_preferences | Fetch authenticated user notification preferences  | GET         |
| /user/notification_preferences | Update authenticated user notification preferences | PUT         |
| /user/password                 | Update authenticated user password                 | PUT         |
| /brigade/{{id}}/members        | List brigade members                               | GET         |
| /occurrence/new                | Register new occurrence                            | POST (Form) |
| /dashboard/stats               | Fetch stats for the dashboard page                 | GET         |

## Entity RelationShip Diagram

```mermaid
---
title: SENAC Brigade
---

erDiagram

    user_account {
        UUID id PK
        USER_ROLE_ENUM user_role
        TEXT full_name
        TEXT password_hash
        TEXT registration
        TEXT phone
        TEXT email UK
        BOOLEAN is_active
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    notification_preference ||--|{ user_account : belongs
    notification_preference {
        UUID id PK
        UUID user_id FK
        NOTIFICATION_TYPE_ENUM notification_type
        BOOLEAN enabled
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

    occurrence_category |o--o{ occurrence_category : subcategory_of
    occurrence_category {
        UUID id PK
        UUID parent_category FK
        TEXT name UK
        TEXT description
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    occurrence }|--|| user_account : submit
    occurrence }|--|| occurrence_category : is
    occurrence {
        UUID id PK
        UUID applicant_id FK
        UUID category FK
        TEXT description
        POINT location
        TEXT reference_point
        TEXT vehicle_code
        UUID[] participants_id
        TIMESTAMP created_at
        TIMESTAMP updated_at
        TIMESTAMP resolved_at
    }

    occurrence_brigade_member }o--o{ user_account : participant
    occurrence_brigade_member }o--o{ brigade : participates_of
    occurrence_brigade_member {
        UUID id
        UUID user_id
        UUID brigade_id
    }
```
