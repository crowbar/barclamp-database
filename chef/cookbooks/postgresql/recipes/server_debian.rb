#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)#
# Copyright 2009-2011, Opscode, Inc.
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
 
include_recipe "postgresql::client"
 
case node[:postgresql][:version]
when "8.3"
  node.default[:postgresql][:ssl] = "off"
else # > 8.3
  node.default[:postgresql][:ssl] = "true"
end

execute "tune-shmmax" do
  command "sysctl -w kernel.shmmax=2147483648"
  action :run
end
 
package "postgresql"
 
# We need to include the HA recipe early, before the config files are
# generated, but after the postgresql packages are installed since they live in
# the directory that will be mounted for HA
if node[:database][:ha][:enabled]
  include_recipe "postgresql::ha_storage"
end

service "postgresql" do
  supports :restart => true, :status => false, :reload => true
  action [:enable, :start]
end
 
template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "debian.postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  notifies :restart, resources(:service => "postgresql")
end
