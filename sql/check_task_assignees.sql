SELECT EXISTS FROM task_assignees WHERE task_id = $1 AND user_id = $2;
