INSERT INTO tasks (name, status, created_at) VALUES ($1, $2, NOW()) RETURNING id;
