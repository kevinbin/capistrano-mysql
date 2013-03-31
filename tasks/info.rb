require File.expand_path(File.dirname(__FILE__) + '/utilities')

namespace :info do
  set :pt_summary, "/usr/local/bin/pt-summary"
  set :pt_mysql_summary, "/usr/local/bin/pt-mysql-summary"
  Dir.mkdir("info") unless File.exist?("info")

  desc "View Server Info"
  task :server do
    upload "#{pt_summary}", "/usr/local/bin", :via => :scp
    run "chmod +x /usr/local/bin/pt-summary"
    run "pt-summary | tee /tmp/server_info |awk '{if($1~/Processors|Models/)print \"CPU\"$0};{if($1 ~/Total/)print \"MEM\"$0}'"
    download "/tmp/server_info", "info/server_info_$CAPISTRANO:HOST$"
  end

  desc "View MySQL Database Info"
  task :mysql, :roles => :sql_hosts do
    upload "#{pt_mysql_summary}", "/usr/local/bin", :via => :scp
    run "chmod +x /usr/local/bin/pt-mysql-summary"
    run "pt-mysql-summary > /tmp/mysql_info"
    download "/tmp/mysql_info", "info/mysql_info_$CAPISTRANO:HOST$"
  end
end