INSERT INTO users (name, created_at) VALUES ($1, NOW()) RETURNING id;
