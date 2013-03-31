require File.expand_path(File.dirname(__FILE__) + '/utilities')

# namespace :setup do
  set :c6_repo, File.join(File.dirname(__FILE__),'../templates/c6-cdrom.repo.erb')
  set :repo_host, `ipconfig getifaddr en1`.chomp
  set :ntpserver, ''
  set :target, File.join(File.dirname(__FILE__),'../config/hosts.yml')

  desc "Setup SSH Public Key login"
  task :ssh_key do
    upload_key "/Users/hongbin/.ssh/id_rsa.pub" "/tmp/pbkey"
    run "mkdir -p ~/.ssh"
    run "cat /tmp/pbkey >> ~/.ssh/authorized_keys"
    run "chmod 600 $HOME/.ssh/authorized_keys"
  end

  desc "Setup CentOS YUM repo"
  task :yum_repo do
    upload_template "#{c6_repo}", "/etc/yum.repos.d/CentOS-CDROM.repo"
  end

  desc "Sync date to host #{ntpserver} "
  task :ntp_sync do
    run "ntpdate #{ntpserver}"
    run "echo '*/10 * * * * ntpdate #{ntpserver}'| crontab -u root -"
  end

  desc "Check host alive with ping"
  task :ping do
    ping_host "#{target}"
  end

  desc "View date and uptime and memory"
  task :uptime do
    run "echo `date +%Y-%m-%d; uptime; free -om|grep Mem`"
  end
# end
