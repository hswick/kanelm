INSERT INTO tasks (name, status, project_id, created_by, created_at) VALUES ($1, $2, $3, NOW()) RETURNING id;
