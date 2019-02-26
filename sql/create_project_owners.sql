CREATE TABLE project_owners(
 id serial PRIMARY KEY,
 project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
 user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
 created_at TIMESTAMP NOT NULL
);
