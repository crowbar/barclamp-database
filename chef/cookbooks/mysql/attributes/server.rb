#
# Cookbook Name:: mysql
# Attributes:: server
#
# Copyright 2008-2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['mysql']['bind_address']              = node['ipaddress']
default['mysql']['storage_engine']            = "InnoDB"
default['mysql']['datadir']                   = "/var/lib/mysql"
default['mysql']['tmpdir']                    = "/var/lib/mysqltmp"
default['mysql']['logdir']                    = "/var/lib/mysqllogs"

case node["platform"]
when "centos", "redhat", "fedora", "suse"
  set['mysql']['socket']                      = "/var/lib/mysql/mysql.sock"
  set['mysql']['pid_file']                    = "/var/run/mysqld/mysqld.pid"
  set['mysql']['old_passwords']               = 1
else
  set['mysql']['socket']                      = "/var/run/mysqld/mysqld.sock"
  set['mysql']['pid_file']                    = "/var/run/mysqld/mysqld.pid"
  set['mysql']['old_passwords']               = 0
end

if attribute?('ec2')
  default['mysql']['ec2_path']                = "/mnt/mysql"
  default['mysql']['ebs_vol_dev']             = "/dev/sdi"
  default['mysql']['ebs_vol_size']            = 50
end

default['mysql']['tunable']['back_log']                 = "128"
default['mysql']['tunable']['key_buffer']               = "256M"
default['mysql']['tunable']['max_allowed_packet']       = "16M"
default['mysql']['tunable']['max_connections']          = "800"
default['mysql']['tunable']['max_heap_table_size']      = "32M"
default['mysql']['tunable']['myisam_recover']           = "BACKUP"
default['mysql']['tunable']['net_read_timeout']         = "30"
default['mysql']['tunable']['net_write_timeout']        = "30"
default['mysql']['tunable']['table_cache']              = "128"
default['mysql']['tunable']['table_open_cache']         = "128"
default['mysql']['tunable']['thread_cache']             = "128"
default['mysql']['tunable']['thread_cache_size']        = 8
default['mysql']['tunable']['thread_concurrency']       = 10
default['mysql']['tunable']['thread_stack']             = "256K"
default['mysql']['tunable']['wait_timeout']             = 28800

default['mysql']['tunable']['query_cache_limit']        = "1M"
default['mysql']['tunable']['query_cache_size']         = "32M"

default['mysql']['tunable']['log_slow_queries']         = "/var/log/mysql/slow.log"
default['mysql']['tunable']['long_query_time']          = 2

# InnoDB Settings
default['mysql']['tunable']['innodb_buffer_pool_size']  = "256M"
default['mysql']['tunable']['innodb_log_buffer_size']   = "8M"
default['mysql']['tunable']['innodb_log_file_size']     = "128M"
default['mysql']['tunable']['innodb_file_per_table']    = 1
default['mysql']['tunable']['innodb_open_files']        = 300

# Replication Settings
default['mysql']['tunable']['server_id']                = "1"
default['mysql']['tunable']['expire_logs_days']         = 10
default['mysql']['tunable']['max_binlog_size']          = "100M"
default['mysql']['tunable']['auto_increment_increment'] = 10
default['mysql']['tunable']['auto_increment_offset']    = 1
