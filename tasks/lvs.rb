require File.expand_path(File.dirname(__FILE__) + '/utilities')

namespace :lvs do
  set :vip, ''

  desc "Setup real server"
  task :setup do
    yum_install "arptables_jf"
    [
    "arptables -A IN -d #{vip} -j DROP",
    "arptables -A OUT -s #{vip} -j mangle --mangle-ip-s $CAPISTRANO:HOST$",
    "service arptables_jf save",
    "ip addr add #{vip} dev lo",
    "echo \"ip addr add #{vip} dev lo\" >> /etc/rc.local"
    ].each {|cmd| run cmd }
  end
end
