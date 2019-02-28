SELECT EXISTS (SELECT * FROM project_owners WHERE project_id = $1 AND user_id = $2 LIMIT 1);
