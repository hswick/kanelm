CREATE TABLE project_owners(
 id serial PRIMARY KEY,
 project_id INTEGER REFERENCES projects(id),
 user_id INTEGER REFERENCES users(id),
 created_at TIMESTAMP NOT NULL
);
