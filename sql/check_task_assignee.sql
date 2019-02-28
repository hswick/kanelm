SELECT EXISTS(SELECT * FROM task_assignees WHERE task_id = $1 AND user_id = $2 LIMIT 1);
