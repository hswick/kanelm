CREATE TABLE tasks(
 id serial PRIMARY KEY,
 project_id INTEGER REFERENCES projects(id),
 created_by INTEGER REFERENCES users(id) NOT NULL,
 updated_by INTEGER REFERENCES users(id),
 name text,
 status text,
 created_at TIMESTAMP NOT NULL,
 updated_at TIMESTAMP
);
