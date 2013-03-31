require File.expand_path(File.dirname(__FILE__) + '/utilities')

namespace :nmon do
  set :nmon_pkg, '/Users/hongbin/tool/nmon_linux_more_14g/nmon_x86_64_rhel45'

  desc "Install nmon"
  task :install do
    upload "#{nmon_pkg}", "/usr/local/bin/nmon", :via => :scp
    run "chmod +x /usr/local/bin/nmon"
  end

  desc "Monitor hosts with nmon"
  task :monitor do
    clean
    run "nmon -s 10 -c 600 -F /tmp/nmon_r"
  end

  desc "Collect nmon result"
  task :collect do
    kill
    File.rename("nmon_results","nmon_results_"+`date +%Y-%m-%d-%H:%M:%S`) if File.exist?("nmon_results")
    Dir.mkdir("nmon_results") unless File.exist?("nmon_results")
    download "/tmp/nmon_r", "nmon_results/nmon_$CAPISTRANO:HOST$"
    clean
  end
  desc "Kill nmon process"
  task :kill do
    run "killall nmon"
  end

  desc "Clean nmon Result"
  task :clean do
    run "rm -f /tmp/nmon_r"
  end

  desc "Show nmon process"
  task :show do
    run "pgrep nmon"
  end
end