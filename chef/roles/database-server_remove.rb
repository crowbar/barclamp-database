name "database-server_remove"
description "Deactivate Database Server Role services"
run_list(
  "recipe[database::deactivate_server]"
)
default_attributes()
override_attributes()
