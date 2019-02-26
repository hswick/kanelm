WITH new_project AS (
 INSERT INTO projects (name, created_by, created_at) VALUES ($1, $2, NOW()) RETURNING id, created_by
)
INSERT INTO project_owners (project_id, user_id, created_at) VALUES (
 (SELECT id FROM new_project),
 (SELECT created_by FROM new_project),
 NOW()
) RETURNING project_id;
