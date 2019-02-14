INSERT INTO projects (name, created_by, created_at) VALUES ($1, $2, NOW()) RETURNING id;
