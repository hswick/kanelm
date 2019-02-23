\i sql/create_users.sql
\i sql/create_login.sql
\i sql/create_projects.sql
\i sql/create_tasks.sql

INSERT INTO users (name, created_at) VALUES ('shiba', NOW());

INSERT INTO login (user_id, password, created_at) VALUES (
 (SELECT id FROM users WHERE name = 'shiba'),
 'foobar',
 NOW()
);
 
 
