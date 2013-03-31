require File.expand_path(File.dirname(__FILE__) + '/utilities')

namespace :ib do
  set :ib_rpm, '/Users/hongbin/tool/infobright/rpm/infobright-4.0.7-0-x86_64-iee.rpm'
  set :dlp_rpm, '/Users/hongbin/tool/infobright/rpm/infobright-dlp-1.2-x86_64-iee.rpm'

  desc "Install Infobright"
  task :install do
    upload "#{ib_rpm}", "/tmp/infobright.rpm", :via => :scp
    stream "rpm -ivh --force /tmp/infobright.rpm"
    run "rm -f /tmp/infobright.rpm"
  end
  desc "Install Infobright DLP"
  task :dlp do
    upload "#{dlp_rpm}", "/tmp/dlp.rpm", :via => :scp
    stream "rpm -ivh --force /tmp/dlp.rpm"
    run "rm -f /tmp/dlp.rpm"
  end

  desc "Start Infobright service"
  task :start do
    stream "service mysqld-ib start"
  end

  desc "Start Infobright service"
  task :stop do
    stream "service mysqld-ib stop"
  end
end
