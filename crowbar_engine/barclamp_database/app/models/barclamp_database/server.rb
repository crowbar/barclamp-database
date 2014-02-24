# Copyright 2013, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class BarclampDatabase::Server < BarclampChef::Role
  include BarclampOpenstack
  def random_password(size = 12)
    chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(o 0 O i 1 l)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end

  # Event triggers for node creation and destruction.
  # roles should override if they want to handle node addition
  def on_node_create(node)
    Rails.logger.info("on_node_create: #{node}")
    true
  end

  # Event triggers for node creation and destruction.
  # roles should override if they want to handle node destruction
  def on_node_delete(node)
    Rails.logger.info("on_node_delete: #{node}")
    true
  end

  # Event hook that will be called every time a node is saved if any attributes changed.
  # Roles that are interested in watching nodes to see what has changed should
  # implement this hook.
  def on_node_change(node)
    Rails.logger.info("on_node_change: #{node}")
    true
  end


  def on_deployment_create(dr)
    DeploymentRole.transaction do
      d = dr.data

      #setup the encrypted data bag with temporary hardcoded values.
      services = ['compute', 'image', 'identity', 'network','dashboard','metering','block-storage','orchestration']
      user_ids = ['nova', 'glance', 'keystone', 'neutron','horizon','ceilometer','cinder','heat']
      password = 'crowbar'

      Rails.logger.info("Adding encrypted db credentials into encrypted data bags")

      for i in (0..services.size-1)
        store_credential( "database", "db", user_ids[i],password )
        #store the attributes
        d.deep_merge!(
            {
                "crowbar" => {
                    "db" =>{
                        services[i] => {
                            "username" => user_ids[i]
                        }
                    }
                }
            }
        )
      end


      Rails.logger.info("#{name}: Generating the mysql passwords #{dr.deployment.name} (#{d.inspect})")
      server_root_password = random_password
      server_repl_password = random_password
      server_debian_password = random_password
      store_credential( "database", "db", "mysqlroot",server_root_password )
      d.deep_merge!(
            {
              "mysql" => {
                          "server_root_password" => server_root_password,
                          "server_repl_password" => server_repl_password ,
                          "server_debian_password" => server_debian_password
                  }
            }
      )
      Rails.logger.info("Merged.")
      dr.data = d
      dr.save!
    end
  end

  # Event hook that is called whenever a deployment role is deleted from a deployment.
  def on_deployment_delete(dr)
    Rails.logger.info("on_deployment_delete: #{dr}")
    true
  end
end
