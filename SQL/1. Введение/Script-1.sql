select table_name, constraint_name
from information_schema.table_constraints
where constraint_type = 'PRIMARY KEY'