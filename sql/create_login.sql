CREATE TABLE login(
 id serial PRIMARY KEY,
 user_id INTEGER REFERENCES users(id),
 password text,
 created_at TIMESTAMP NOT NULL,
 updated_at TIMESTAMP
);
