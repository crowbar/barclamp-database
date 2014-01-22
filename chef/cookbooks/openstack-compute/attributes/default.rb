########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = false  # OS provides packages
########################################################################

# Set to some text value if you want templated config files
# to contain a custom banner at the top of the written file
default["openstack"]["compute"]["custom_template_banner"] = "
# This file autogenerated by Chef
# Do not edit, changes will be overwritten
"

# The name of the Chef role that knows about the message queue server
# that Nova uses
default["openstack"]["compute"]["rabbit_server_chef_role"] = "os-ops-messaging"

default["openstack"]["compute"]["verbose"] = "False"
default["openstack"]["compute"]["debug"] = "False"

# The name of the Chef role that sets up the Keystone Service API
default["openstack"]["compute"]["identity_service_chef_role"] = "os-identity"

# This user's password is stored in an encrypted databag
# and accessed with openstack-common cookbook library's
# db_password routine.
default["openstack"]["compute"]["db"]["username"] = "nova"

# Common rpc definitions
default["openstack"]["compute"]["rpc_thread_pool_size"] = 64
default["openstack"]["compute"]["rpc_conn_pool_size"] = 30
default["openstack"]["compute"]["rpc_response_timeout"] = 60

# This user's password is stored in an encrypted databag
# and accessed with openstack-common cookbook library's
# user_password routine.  You are expected to create
# the user, pass, vhost in a wrapper rabbitmq cookbook.
default["openstack"]["compute"]["rabbit"]["username"] = "guest"
default["openstack"]["compute"]["rabbit"]["vhost"] = "/"
default["openstack"]["compute"]["rabbit"]["port"] = 5672
default["openstack"]["compute"]["rabbit"]["host"] = "127.0.0.1"
default["openstack"]["compute"]["rabbit"]["ha"] = false

default["openstack"]["compute"]["service_tenant_name"] = "service"
default["openstack"]["compute"]["service_user"] = "nova"
default["openstack"]["compute"]["service_role"] = "admin"

case platform
when "fedora", "redhat", "centos", "ubuntu"
  default["openstack"]["compute"]["user"] = "nova"
  default["openstack"]["compute"]["group"] = "nova"
when "suse"
  default["openstack"]["compute"]["user"] = "openstack-nova"
  default["openstack"]["compute"]["group"] = "openstack-nova"
end

# Logging stuff
default["openstack"]["compute"]["syslog"]["use"] = false
default["openstack"]["compute"]["syslog"]["facility"] = "LOG_LOCAL1"
default["openstack"]["compute"]["syslog"]["config_facility"] = "local1"

default["openstack"]["compute"]["region"] = "RegionOne"

default["openstack"]["compute"]["floating_cmd"] = "/usr/local/bin/add_floaters.py"

# Support multiple network types.  Default network type is "nova"
# with the other option supported being "quantum"
default["openstack"]["compute"]["network"]["service_type"] = "nova"

# if the network type is not nova, we will load the following
# plugins from openstack-network
default["openstack"]["compute"]["network"]["plugins"] = ["openvswitch"]

# MQ options
default["openstack"]["compute"]["mq"]["service_type"] = node["openstack"]["mq"]["service_type"]
default["openstack"]["compute"]["mq"]["qpid"]["host"] = "127.0.0.1"
default["openstack"]["compute"]["mq"]["qpid"]["port"] = "5672"
default["openstack"]["compute"]["mq"]["qpid"]["qpid_hosts"] = ['127.0.0.1:5672']

default["openstack"]["compute"]["mq"]["qpid"]["username"] = ""
default["openstack"]["compute"]["mq"]["qpid"]["password"] = ""
default["openstack"]["compute"]["mq"]["qpid"]["sasl_mechanisms"] = ""
default["openstack"]["compute"]["mq"]["qpid"]["reconnect_timeout"] = 0
default["openstack"]["compute"]["mq"]["qpid"]["reconnect_limit"] = 0
default["openstack"]["compute"]["mq"]["qpid"]["reconnect_interval_min"] = 0
default["openstack"]["compute"]["mq"]["qpid"]["reconnect_interval_max"] = 0
default["openstack"]["compute"]["mq"]["qpid"]["reconnect_interval"] = 0
default["openstack"]["compute"]["mq"]["qpid"]["heartbeat"] = 60
default["openstack"]["compute"]["mq"]["qpid"]["protocol"] = "tcp"
default["openstack"]["compute"]["mq"]["qpid"]["tcp_nodelay"] = true


# Quantum options
default["openstack"]["compute"]["network"]["quantum"]["network_api_class"] = "nova.network.quantumv2.api.API"
default["openstack"]["compute"]["network"]["quantum"]["auth_strategy"] = "keystone"
default["openstack"]["compute"]["network"]["quantum"]["admin_tenant_name"] = "service"
default["openstack"]["compute"]["network"]["quantum"]["admin_username"] = "quantum"
default["openstack"]["compute"]["network"]["quantum"]["libvirt_vif_driver"] = "nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver"
default["openstack"]["compute"]["network"]["quantum"]["linuxnet_interface_driver"] = "nova.network.linux_net.LinuxOVSInterfaceDriver"
default["openstack"]["compute"]["network"]["quantum"]["security_group_api"] = "quantum"
default["openstack"]["compute"]["network"]["quantum"]["service_quantum_metadata_proxy"] = true
default["openstack"]["compute"]["network"]["quantum"]["metadata_secret_name"] = "quantum_metadata_shared_secret"
default["openstack"]["compute"]["network"]["quantum"]["public_network_name"] = "public"
default["openstack"]["compute"]["network"]["quantum"]["dns_server"] = "8.8.8.8"

# TODO(shep): This should probably be ["openstack"]["compute"]["network"]["fixed"]
default["openstack"]["compute"]["networks"] = [
  {
    "label" => "public",
    "ipv4_cidr" => "192.168.100.0/24",
    "num_networks" => "1",
    "network_size" => "255",
    "bridge" => "br100",
    "bridge_dev" => "eth2",
    "dns1" => "8.8.8.8",
    "dns2" => "8.8.4.4",
    "multi_host" => 'T'
  },
  {
    "label" => "private",
    "ipv4_cidr" => "192.168.200.0/24",
    "num_networks" => "1",
    "network_size" => "255",
    "bridge" => "br200",
    "bridge_dev" => "eth3",
    "dns1" => "8.8.8.8",
    "dns2" => "8.8.4.4",
    "multi_host" => 'T'
  }
]

# For VLAN Networking, do the following:
#
# default["openstack"]["compute"]["network"]["network_manager"] = "nova.network.manager.VlanManager"
# default["openstack"]["compute"]["network"]["vlan_interface"] = "eth1"  # Or "eth2", "bond1", etc...
# # The fixed_range setting is the **entire** subnet/network that all your VLAN
# # networks will fit inside.
# default["openstack"]["compute"]["network"]["fixed_range"] = "10.0.0.0/8"  # Or smaller for smaller deploys...
#
# In addition to the above, you typically either want to do one of the following:
#
# 1) Set default["openstack"]["compute"]["networks"] to an empty Array ([]) and create your
#    VLAN networks (using nova-manage network create) **when you create a tenant**.
#
# 2) Set default["openstack"]["compute"]["networks"] to an Array of VLAN networks that get created
#    **without a tenant assignment** for tenants to use when they are created later.
#    Such an array might look like this:
#
#    default["openstack"]["compute"]["networks"] = [
#       {
#         "label": "vlan100",
#         "vlan": "100",
#         "ipv4_cidr": "10.0.100.0/24"
#       },
#       {
#         "label": "vlan101",
#         "vlan": "101",
#         "ipv4_cidr": "10.0.101.0/24"
#       },
#       {
#         "label": "vlan102",
#         "vlan": "102",
#         "ipv4_cidr": "10.0.102.0/24"
#       },
#   ]

default["openstack"]["compute"]["network"]["multi_host"] = false
default["openstack"]["compute"]["network"]["fixed_range"] = default["openstack"]["compute"]["networks"][0]["ipv4_cidr"]
# DMZ CIDR is a range of IP addresses that should not
# have their addresses SNAT'ed by the nova network controller
default["openstack"]["compute"]["network"]["dmz_cidr"] = "10.128.0.0/24"
default["openstack"]["compute"]["network"]["network_manager"] = "nova.network.manager.FlatDHCPManager"
default["openstack"]["compute"]["network"]["public_interface"] = "eth0"
default["openstack"]["compute"]["network"]["vlan_interface"] = "eth0"
default["openstack"]["compute"]["network"]["auto_assign_floating_ip"] = false
# https://bugs.launchpad.net/nova/+bug/1075859
default["openstack"]["compute"]["network"]["use_single_default_gateway"] = false

default["openstack"]["compute"]["scheduler"]["scheduler_driver"] = "nova.scheduler.filter_scheduler.FilterScheduler"
default["openstack"]["compute"]["scheduler"]["default_filters"] = [
  "AvailabilityZoneFilter",
  "RamFilter",
  "ComputeFilter",
  "CoreFilter",
  "SameHostFilter",
  "DifferentHostFilter"
]

default["openstack"]["compute"]["xvpvnc_proxy"]["service_port"] = "6081"
default["openstack"]["compute"]["xvpvnc_proxy"]["bind_interface"] = "lo"
default["openstack"]["compute"]["novnc_proxy"]["service_port"] = "6080"
default["openstack"]["compute"]["novnc_proxy"]["bind_interface"] = "lo"

default["openstack"]["compute"]["driver"] = "libvirt.LibvirtDriver"
default["openstack"]["compute"]["libvirt"]["virt_type"] = "kvm"
default["openstack"]["compute"]["libvirt"]["bind_interface"] = "lo"
default["openstack"]["compute"]["libvirt"]["auth_tcp"] = "none"
default["openstack"]["compute"]["libvirt"]["remove_unused_base_images"] = true
default["openstack"]["compute"]["libvirt"]["remove_unused_resized_minimum_age_seconds"] = 3600
default["openstack"]["compute"]["libvirt"]["remove_unused_original_minimum_age_seconds"] = 3600
default["openstack"]["compute"]["libvirt"]["checksum_base_images"] = false
# libvirt.max_clients (default: 20)
default["openstack"]["compute"]["libvirt"]["max_clients"] = 20
# libvirt.max_workers (default: 20)
default["openstack"]["compute"]["libvirt"]["max_workers"] = 20
# libvirt.max_requests (default: 20)
default["openstack"]["compute"]["libvirt"]["max_requests"] = 20
# libvirt.max_client_requests (default: 5)
default["openstack"]["compute"]["libvirt"]["max_client_requests"] = 5
if node["platform"] == "suse"
  default["openstack"]["compute"]["libvirt"]["group"] = "libvirt"
else
  default["openstack"]["compute"]["libvirt"]["group"] = "libvirtd"
end
default["openstack"]["compute"]["libvirt"]["libvirt_inject_password"] = false
default["openstack"]["compute"]["config"]["availability_zone"] = "nova"
default["openstack"]["compute"]["config"]["storage_availability_zone"] = "nova"
default["openstack"]["compute"]["config"]["default_schedule_zone"] = "nova"
default["openstack"]["compute"]["config"]["force_raw_images"] = false
default["openstack"]["compute"]["config"]["allow_same_net_traffic"] = true
default["openstack"]["compute"]["config"]["osapi_max_limit"] = 1000
default["openstack"]["compute"]["config"]["cpu_allocation_ratio"] = 16.0
default["openstack"]["compute"]["config"]["ram_allocation_ratio"] = 1.5
default["openstack"]["compute"]["config"]["disk_allocation_ratio"] = 1.0
default["openstack"]["compute"]["config"]["snapshot_image_format"] = "qcow2"
default["openstack"]["compute"]["config"]["allow_resize_to_same_host"] = false
# `start` will cause nova-compute to error out if a VM is already running, where
# `resume` checks to see if it is running first.
default["openstack"]["compute"]["config"]["start_guests_on_host_boot"] = false
# requires https://review.openstack.org/#/c/8423/
default["openstack"]["compute"]["config"]["resume_guests_state_on_host_boot"] = true

# If true, create a config drive regardless of if the user specified --config-drive true in their nova boot call
default["openstack"]["compute"]["config"]["force_config_drive"] = "false"

# Volume API class (driver)
default["openstack"]["compute"]["config"]["volume_api_class"] = "nova.volume.cinder.API"

# quota settings
default["openstack"]["compute"]["config"]["quota_security_groups"] = 50
default["openstack"]["compute"]["config"]["quota_security_group_rules"] = 20
# (StrOpt) default driver to use for quota checks (default: nova.quota.DbQuotaDriver)
default["openstack"]["compute"]["config"]["quota_driver"] = "nova.quota.DbQuotaDriver"
# number of instance cores allowed per project (default: 20)
default["openstack"]["compute"]["config"]["quota_cores"] = 20
# number of fixed ips allowed per project (this should be at least the number of instances allowed) (default: -1)
default["openstack"]["compute"]["config"]["quota_fixed_ips"] = -1
# number of floating ips allowed per project (default: 10)
default["openstack"]["compute"]["config"]["quota_floating_ips"] = 10
# number of bytes allowed per injected file (default: 10240)
default["openstack"]["compute"]["config"]["quota_injected_file_content_bytes"] = 10240
# number of bytes allowed per injected file path (default: 255)
default["openstack"]["compute"]["config"]["quota_injected_file_path_bytes"] = 255
# number of injected files allowed (default: 5)
default["openstack"]["compute"]["config"]["quota_injected_files"] = 5
# number of instances allowed per project (defailt: 10)
default["openstack"]["compute"]["config"]["quota_instances"] = 10
# number of key pairs per user (default: 100)
default["openstack"]["compute"]["config"]["quota_key_pairs"] = 100
# number of metadata items allowed per instance (default: 128)
default["openstack"]["compute"]["config"]["quota_metadata_items"] = 128
# megabytes of instance ram allowed per project (default: 51200)
default["openstack"]["compute"]["config"]["quota_ram"] = 51200

default["openstack"]["compute"]["ratelimit"]["settings"] = {
  "generic-post-limit" => { "verb" => "POST", "uri" => "*", "regex" => ".*", "limit" => "10", "interval" => "MINUTE" },
  "create-servers-limit" => { "verb" => "POST", "uri" => "*/servers", "regex" => "^/servers", "limit" => "50", "interval" => "DAY" },
  "generic-put-limit" => { "verb" => "PUT", "uri" => "*", "regex" => ".*", "limit" => "10", "interval" => "MINUTE" },
  "changes-since-limit" => { "verb" => "GET", "uri" => "*changes-since*", "regex" => ".*changes-since.*", "limit" => "3", "interval" => "MINUTE" },
  "generic-delete-limit" => { "verb" => "DELETE", "uri" => "*", "regex" => ".*", "limit" => "100", "interval" => "MINUTE" }
}

# Keystone settings
default["openstack"]["compute"]["api"]["auth_strategy"] = "keystone"

# Setting this to v2.0. See discussion on
# https://bugs.launchpad.net/openstack-chef/+bug/1207504
default["openstack"]["compute"]["api"]["auth"]["version"] = "v2.0"

# Keystone PKI signing directories
default["openstack"]["compute"]["api"]["auth"]["cache_dir"] = "/var/cache/nova/api"

# Perform nova-conductor operations locally (boolean value)
default["openstack"]["compute"]["conductor"]["use_local"] = "False"

default["openstack"]["compute"]["network"]["force_dhcp_release"] = true

case platform
when "fedora", "redhat", "centos", "suse" # :pragma-foodcritic: ~FC024 - won't fix this
  default["openstack"]["compute"]["platform"] = {
    "api_ec2_packages" => ["openstack-nova-api"],
    "api_ec2_service" => "openstack-nova-api",
    "api_os_compute_packages" => ["openstack-nova-api"],
    "api_os_compute_service" => "openstack-nova-api",
    "api_os_compute_process_name" => "nova-api",
    "neutron_python_packages" => ["python-quantumclient", "pyparsing"],
    "memcache_python_packages" => ["python-memcached"],
    "compute_api_metadata_packages" => ["openstack-nova-api"],
    "compute_api_metadata_process_name" => "nova-api",
    "compute_api_metadata_service" => "openstack-nova-api",
    "compute_compute_packages" => ["openstack-nova-compute"],
    "compute_compute_service" => "openstack-nova-compute",
    "compute_network_packages" => ["iptables", "openstack-nova-network"],
    "compute_network_service" => "openstack-nova-network",
    "compute_scheduler_packages" => ["openstack-nova-scheduler"],
    "compute_scheduler_service" => "openstack-nova-scheduler",
    "compute_conductor_packages" => ["openstack-nova-conductor"],
    "compute_conductor_service" => "openstack-nova-conductor",
    "compute_vncproxy_packages" => ["openstack-nova-novncproxy"], # me thinks this is right?
    "compute_vncproxy_service" => "openstack-nova-novncproxy",
    "compute_vncproxy_consoleauth_packages" => ["openstack-nova-console"],
    "compute_vncproxy_consoleauth_service" => "openstack-nova-consoleauth",
    "compute_vncproxy_consoleauth_process_name" => "nova-consoleauth",
    "libvirt_packages" => ["libvirt"],
    "libvirt_service" => "libvirtd",
    "dbus_service" => "messagebus",
    "compute_cert_packages" => ["openstack-nova-cert"],
    "compute_cert_service" => "openstack-nova-cert",
    "mysql_service" => "mysqld",
    "common_packages" => ["openstack-nova-common"],
    "iscsi_helper" => "ietadm",
    "nfs_packages" => ["nfs-utils", "nfs-utils-lib"],
    "package_overrides" => ""
  }
  if platform == "suse"
    default["openstack"]["compute"]["platform"]["dbus_service"] = "dbus"
    default["openstack"]["compute"]["platform"]["neutron_python_packages"] = ["python-quantumclient", "python-pyparsing"]
    default["openstack"]["compute"]["platform"]["common_packages"] = ["openstack-nova"]
    default["openstack"]["compute"]["platform"]["kvm_packages"] = ["kvm"]
    default["openstack"]["compute"]["platform"]["xen_packages"] = ["kernel-xen", "xen", "xen-tools"]
    default["openstack"]["compute"]["platform"]["lxc_packages"] = ["lxc"]
    default["openstack"]["compute"]["platform"]["nfs_packages"] = ["nfs-utils"]
  end
  # Since the bug (https://bugzilla.redhat.com/show_bug.cgi?id=788485) not released in epel yet
  # For "fedora", "redhat", "centos", we need set the default value of force_dhcp_release is 'false'
  default["openstack"]["compute"]["network"]["force_dhcp_release"] = false
when "ubuntu"
  default["openstack"]["compute"]["platform"] = {
    "api_ec2_packages" => ["nova-api-ec2"],
    "api_ec2_service" => "nova-api-ec2",
    "api_os_compute_packages" => ["nova-api-os-compute"],
    "api_os_compute_process_name" => "nova-api-os-compute",
    "api_os_compute_service" => "nova-api-os-compute",
    "memcache_python_packages" => ["python-memcache"],
    "neutron_python_packages" => ["python-quantumclient", "python-pyparsing"],
    "compute_api_metadata_packages" => ["nova-api-metadata"],
    "compute_api_metadata_service" => "nova-api-metadata",
    "compute_api_metadata_process_name" => "nova-api-metadata",
    "compute_compute_packages" => ["nova-compute"],
    "compute_compute_service" => "nova-compute",
    "compute_network_packages" => ["iptables", "nova-network"],
    "compute_network_service" => "nova-network",
    "compute_scheduler_packages" => ["nova-scheduler"],
    "compute_scheduler_service" => "nova-scheduler",
    "compute_conductor_packages" => ["nova-conductor"],
    "compute_conductor_service" => "nova-conductor",
    # Websockify is needed due to https://bugs.launchpad.net/ubuntu/+source/nova/+bug/1076442
    "compute_vncproxy_packages" => ["novnc", "websockify", "nova-novncproxy"],
    "compute_vncproxy_service" => "nova-novncproxy",
    "compute_vncproxy_consoleauth_packages" => ["nova-consoleauth"],
    "compute_vncproxy_consoleauth_service" => "nova-consoleauth",
    "compute_vncproxy_consoleauth_process_name" => "nova-consoleauth",
    "libvirt_packages" => ["libvirt-bin"],
    "libvirt_service" => "libvirt-bin",
    "dbus_service" => "dbus",
    "compute_cert_packages" => ["nova-cert"],
    "compute_cert_service" => "nova-cert",
    "mysql_service" => "mysql",
    "common_packages" => ["nova-common"],
    "iscsi_helper" => "tgtadm",
    "nfs_packages" => ["nfs-common"],
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end

# plugins
default["openstack"]["compute"]["plugins"] = nil

# To disable the EC2 API endpoint, simply remove "ec2," from the list
# of enabled API services.
default["openstack"]["compute"]["enabled_apis"] = "ec2,osapi_compute,metadata"
