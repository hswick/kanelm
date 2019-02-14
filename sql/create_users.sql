CREATE TABLE IF NOT EXISTS users(
 id serial PRIMARY KEY,
 name text,
 created_at TIMESTAMP NOT NULL,
 updated_at TIMESTAMP
);
