CREATE TABLE tasks(
 task_id serial PRIMARY KEY,
 name text,
 status text,
 created_on TIMESTAMP NOT NULL,
 updated_on TIMESTAMP
);
