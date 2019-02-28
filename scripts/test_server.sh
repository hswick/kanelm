psql -d kanelm -a -f sql/test_env.sql
go test -v
psql -d kanelm -a -f sql/clean.sql
