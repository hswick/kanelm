CREATE TABLE IF NOT EXISTS projects(
 id serial PRIMARY KEY,
 created_by INTEGER REFERENCES users(id),
 name text,
 created_at TIMESTAMP NOT NULL,
 updated_at TIMESTAMP
);
