
def yum_install(packages)
  packages = packages.split(/\s+/) if packages.respond_to?(:split)
  packages = Array(packages)
  stream "yum -y install #{packages.join(" ")}"
end

def upload_template(src,dst,options = {})
  raise Capistrano::Error, "put_template requires Source and Destination" if src.nil? or dst.nil?
  put ERB.new(File.read(src)).result(binding), dst, options
end

def upload_key(keys,dst,options = {})
  ssh_key = File.read(keys)
  put ssh_key, dst, options
end


def ping_host(config)
  # File.read(hostfile).gsub(/^#.*\n/, "").each_line do |line|
  # host = line.chomp
  YAML.load_file(config).each_value do |v|
    v.each do |host|
      if system("ping -c 3 #{host}" + " > /dev/null")
        puts "Host: #{host} \033[32mYep!\033[0m"
      else
        puts "Host: #{host} \033[31mOops!\033[0m"
      end
    end
  end
end

def host_define(config, role)
  res = YAML.load_file(config)
  return res[role]
end

# def host_defin(config)
#   res = YAML.load_file(config)
#   res.each do |k,v|
#   set :mysql_master, k
#     {:slaves => v}
#   end
# end

# def host(hostfile)
#   host_a = File.read(hostfile).split(/\n/)
#   return host_a
# end

