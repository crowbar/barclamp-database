# -*- encoding : utf-8 -*-
#/postgresql.conf.
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Author:: Ralf Haferkamp (<rhafer@suse.com>)
# Copyright 2009-2011, Opscode, Inc.
# Copyright 2012, SUSE
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
 
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
 
include_recipe "postgresql::client"
 
# randomly generate postgres password
node.set_unless[:postgresql][:password][:postgres] = secure_password
node.save unless Chef::Config[:solo]
 
case node[:postgresql][:version]
when "8.3"
  node.default[:postgresql][:ssl] = "off"
when "8.4"
  node.default[:postgresql][:ssl] = "true"
end

# For Crowbar, we need to set the address to bind - default to admin node.
addr = node['postgresql']['listen_addresses'] || ""
newaddr = CrowbarDatabaseHelper.get_listen_address(node)
if addr != newaddr
  node['postgresql']['listen_addresses'] = newaddr
  node.save
end
# We also need to add the network + mask to give access to other nodes
# in pg_hba.conf
netaddr = node['postgresql']['network_address'] || ""
netmask = node['postgresql']['network_mask'] || ""
newnetaddr = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").subnet
newnetmask = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").netmask
if netaddr != newnetaddr or netmask != newnetmask
  node['postgresql']['network_address'] = newnetaddr
  node['postgresql']['network_mask'] = newnetmask
  node.save
end

# While we would like to include the "postgresql::ha_storage" recipe from here,
# it's not possible: we need to have the packages installed first, and we need
# to include it before we do templates. Which means we need to do it in the
# server_* recipe directly, since they do both.

# Include the right "family" recipe for installing the server
# since they do things slightly differently.
case node.platform
when "redhat", "centos", "fedora", "suse", "scientific", "amazon"
  include_recipe "postgresql::server_redhat"
when "debian", "ubuntu"
  include_recipe "postgresql::server_debian"
end
 
template "#{node[:postgresql][:dir]}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  if (node[:postgresql][:version] == "8.3")
    variables( :ident => "sameuser" )
  else
    variables( :ident => "" )
  end
  notifies :reload, resources(:service => "postgresql"), :immediately
end

ha_enabled = node[:database][:ha][:enabled]

if ha_enabled
  log "HA support for postgresql is enabled"
  include_recipe "postgresql::ha"

  # Only run the psql commands if the service is running on this node, so that
  # we don't depend on the node running the service to be as fast as this one
  service_name = "postgresql"
  only_if_command = "crm resource show #{service_name} | grep -q \" #{node.hostname} *$\""
else
  log "HA support for postgresql is disabled"
end

# Default PostgreSQL install has 'ident' checking on unix user 'postgres'
# and 'md5' password checking with connections from 'localhost'. This script
# runs as user 'postgres', so we can execute the 'role' and 'database' resources
# as 'root' later on, passing the below credentials in the PG client.
bash "assign-postgres-password" do
  user 'postgres'
  code <<-EOH
echo "ALTER ROLE postgres ENCRYPTED PASSWORD '#{node[:postgresql][:password][:postgres]}';" | psql
  EOH
  not_if do
    begin
      require 'rubygems'
      Gem.clear_paths
      require 'pg'
      conn = PGconn.connect(:host => newaddr, :port => 5432, :dbname => "postgres", :user => "postgres", :password =>  node['postgresql']['password']['postgres'])
    rescue PGError
      false
    end
  end
  only_if only_if_command if ha_enabled
  action :run
end

# For Crowbar we also need the "db_maker" user
bash "assign-db_maker-password" do
  user 'postgres'
  code <<-EOH
echo "CREATE ROLE db_maker WITH LOGIN CREATEDB CREATEROLE ENCRYPTED PASSWORD '#{node[:database][:db_maker_password]}';
ALTER ROLE db_maker ENCRYPTED PASSWORD '#{node[:database][:db_maker_password]}';" | psql
  EOH
  not_if do
    begin
      require 'rubygems'
      Gem.clear_paths
      require 'pg'
      conn = PGconn.connect(:host => newaddr, :port => 5432, :dbname => "postgres", :user => "db_maker", :password => node['database']['db_maker_password'])
    rescue PGError
      false
    end
  end
  only_if only_if_command if ha_enabled
  action :run
end
