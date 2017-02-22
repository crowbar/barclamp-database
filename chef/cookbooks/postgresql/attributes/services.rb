case node["platform"]
when "suse"
  default["database"]["services"] = {
    "server" => {
      "postgresql" => ["postgresql"]
    }
  }
end
