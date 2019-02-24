CREATE TABLE task_assignees(
 id serial PRIMARY KEY,
 user_id INTEGER REFERENCES users(id),
 task_id INTEGER REFERENCES tasks(id),
 created_at TIMESTAMP NOT NULL
);
