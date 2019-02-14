INSERT INTO tasks (name, status, project_id, created_by, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING id;
