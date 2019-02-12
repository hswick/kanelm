CREATE TABLE IF NOT EXISTS tasks(
 id serial PRIMARY KEY,
 name text,
 status text,
 created_at TIMESTAMP NOT NULL,
 updated_at TIMESTAMP
);
