UPDATE login SET password = $2, updated_at = NOW() WHERE user_id = $1;
