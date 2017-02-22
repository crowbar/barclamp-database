case node["platform"]
when "suse"
  default["database"]["services"] = {
    "server" => {
      "mysql" => ["mysql"]
    }
  }
end
