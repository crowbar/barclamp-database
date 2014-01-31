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

class BarclampDatabase::Server < Role

  def random_password(size = 12)
    chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(o 0 O i 1 l)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end

  def on_deployment_create(dr)
    DeploymentRole.transaction do
      d = dr.data
      Rails.logger.info("#{name}: Generating the mysql passwords #{dr.deployment.name} (#{d.inspect})")
      d.deep_merge!(
            {
              "mysql" => {"server_root_password" => random_password,
                          "server_repl_password" => random_password,
                          "server_debian_password" => random_password
                  }
            }
      )
      Rails.logger.info("Merged.")
      dr.data = d
      dr.save!
    end
  end
end
