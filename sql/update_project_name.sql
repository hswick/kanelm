UPDATE projects SET name = $2, updated_at = NOW() WHERE id = $1;
