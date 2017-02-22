unless node['roles'].include?('database-server')
  node["database"]["services"]["server"]["postgresql"].each do |name|
    service name do
      action [:stop, :disable]
    end
  end
  node.delete('database')
  node.save
end
