require File.expand_path(File.dirname(__FILE__) + '/utilities')

namespace :tpcc do
  set :tpcc_pkg, '/Users/hongbin/tool/tpcc-mysql.tar.gz'

  desc "Install TPCC-MySQL"
  task :install do
    upload "#{tpcc_pkg}", "/tmp", :via => :scp
    run "tar xf /tmp/tpcc-mysql.tar.gz -C /usr/local"
    run "cd /usr/local/tpcc-mysql/src && make"
  end

  desc "Collect tpcc result"
  task :collect do
    File.rename("tpcc_result","tpcc_result"+`date +%Y-%m-%d-%H-%M-%S`) if File.exist?("tpcc_result")
    # Dir.mkdir("tpcc_results") unless File.exist?("tpcc_results")
    download "/root/tpcc-mysql-cluster/result/tpcc_result", "tpcc_result"
  end
  desc "Show tpcc process"
  task :log  do
    stream "tailf /root/tpcc-mysql-cluster/result/tpcc_result"
  end
  desc "Analyse tpcc result"
  task :analyse do
    stream "awk 'BEGIN {printf \"%s\\t%s\\n\", \"Connect\",\"TpmC\"}; {if ($0 ~ /connection/){printf \"%s\\t\", $2} ;if ($0 ~/[0-9].*TpmC/) {print $1}}' /root/tpcc-mysql-cluster/result/tpcc_result"
  end
end

# awk 'BEGIN {printf "%s\t%s\n", "Connect","TpmC"}; {if ($0 ~ /connection/){printf "%s\t", $2} ;if ($0 ~/[0-9].*TpmC/) {print $1}}' tpcc_result