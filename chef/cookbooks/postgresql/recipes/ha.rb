# Copyright 2014 SUSE
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

# We do the HA setup in two steps:
#  - we need to create the vip / storage resources before creating the
#    configuration files (that will be on the mounted device)
#  - we need to create the configuration files before starting postgresql (and
#    therefore creating the primitive for the service and the group)
# There's no magic, we have to follow that order.
#
# This is the second step.

vhostname = CrowbarDatabaseHelper.get_ha_vhostname(node)

vip_primitive = "vip-admin-#{vhostname}"
portblock_primitive = "portblock-admin-#{vhostname}"
portunblock_primitive = "portunblock-admin-#{vhostname}"
service_name = "postgresql"
fs_primitive = "fs-#{service_name}"
group_name = "g-#{service_name}"

agent_name = "ocf:heartbeat:pgsql"

ip_addr = CrowbarDatabaseHelper.get_listen_address(node)

postgres_op = {}
postgres_op["monitor"] = {}
postgres_op["monitor"]["interval"] = "10s"

# Wait for all "database" nodes to reach this point so we know that 
# they will have all the required packages installed and configuration 
# files updated before we create the pacemaker resources.
crowbar_pacemaker_sync_mark "sync-database_before_ha" do
  revision node[:database]["crowbar-revision"]
end

# Avoid races when creating pacemaker resources
crowbar_pacemaker_sync_mark "wait-database_ha_resources" do
  revision node[:database]["crowbar-revision"]
end

pacemaker_primitive vip_primitive do
  agent "ocf:heartbeat:IPaddr2"
  params ({
    "ip" => ip_addr,
  })
  op postgres_op
  action :create
end

pacemaker_primitive portblock_primitive do
  agent "ocf:heartbeat:portblock"
  params ({
    "protocol" => "tcp",
    "ip" => ip_addr,
    "portno" => node['postgresql']['config']['port'],
    "action" => "block"
  })
  op postgres_op
  action :create
end

pacemaker_primitive portunblock_primitive do
  agent "ocf:heartbeat:portblock"
  params ({
    "protocol" => "tcp",
    "ip" => ip_addr,
    "portno" => node['postgresql']['config']['port'],
    "action" => "unblock"
  })
  op postgres_op
  action :create
end

# We run the resource agent "ocf:heartbeat:pgsql" without params, instead of
# something like:
#  params ({
#    "pghost" => CrowbarDatabaseHelper.get_listen_address(node),
#    "monitor_user" => "postgres",
#    "monitor_password" => node['postgresql']['password']['postgres']
#  })
#
# The reason is that the first time the resource is started, the password has
# not been setup and is not correct, so the monitor action will fail, which can
# result in bad things.
#
# It turns out it's no big issue, as the vip primitive will check for the IP
# address, and the pgsql RA will do its "select now()" query locally (instead
# of through the IP address). So we're still monitoring what we want, although
# in two different steps -- and strictly speaking, we're not monitoring the
# fact that the database is listening on the IP address.
pacemaker_primitive service_name do
  agent agent_name
  op postgres_op
  action :create
end

if node[:database][:ha][:storage][:mode] == "drbd"

  pacemaker_colocation "col-#{service_name}" do
    score "inf"
    resources [fs_primitive, portblock_primitive, vip_primitive, service_name, portunblock_primitive]
    action :create
  end

  pacemaker_order "o-#{service_name}" do
    score "Mandatory"
    ordering "#{fs_primitive} #{portblock_primitive} #{vip_primitive} #{service_name} #{portunblock_primitive}"
    action :create
    # This is our last constraint, so we can finally start service_name
    notifies :run, "execute[Cleanup #{service_name} after constraints]", :immediately
    notifies :start, "pacemaker_primitive[#{service_name}]", :immediately
  end

  # This is needed because we don't create all the pacemaker resources in the
  # same transaction, so we will need to cleanup before starting
  execute "Cleanup #{service_name} after constraints" do
    command "sleep 2; crm resource cleanup #{service_name}"
    action :nothing
  end

else

  pacemaker_group group_name do
    # Membership order *is* significant; VIPs should come first so
    # that they are available for the service to bind to.
    members [fs_primitive, portblock_primitive, vip_primitive, service_name, portunblock_primitive]
    action [ :create, :start ]
  end

end

crowbar_pacemaker_sync_mark "create-database_ha_resources" do
  revision node[:database]["crowbar-revision"]
end

# wait for service to be active, and really ready before we go on (because we
# will then need the database to be ready to answer queries)
ruby_block "wait for #{service_name} to be started" do
  block do
    require 'timeout'
    begin
      Timeout.timeout(20) do
        # Check that the service is running
        cmd = "crm resource show #{service_name} 2> /dev/null | grep -q \"is running on\""
        while ! ::Kernel.system(cmd)
          Chef::Log.debug("#{service_name} still not started")
          sleep(2)
        end
        # Check that the service is available, if it's running on this node
        cmd = "crm resource show #{service_name} | grep -q \" #{node.hostname} *$\""
        if ::Kernel.system(cmd)
          cmd = "su - postgres -c 'psql -c \"select now();\"' &> /dev/null"
          while ! ::Kernel.system(cmd)
            Chef::Log.debug("#{service_name} still not answering")
            sleep(2)
          end
        end
      end
    rescue Timeout::Error
      message = "The #{service_name} pacemaker resource is not started. Please manually check for an error."
      Chef::Log.fatal(message)
      raise message
    end
  end # block
end # ruby_block
