require File.expand_path(File.dirname(__FILE__) + '/utilities')

role(:mgm_hosts) {host_define("config/hosts.yml", "mgm_hosts")}
role(:ndb_hosts) {host_define("config/hosts.yml", "ndb_hosts")}
role(:sql_hosts) {host_define("config/hosts.yml", "sql_hosts")}

set :prefix, "/usr/local"
set :mysql_basedir, "#{prefix}/mysql-cluster"
set :data_dir, "/data/test_backup"
set :mgm_conf_temp, 'templates/config.ini.erb'
set :mgm_conf_path, "#{data_dir}/config.ini"
set :mysql_conf_temp, 'templates/my_ndb.cnf.erb'
set :mysql_conf_path, "/etc/my.cnf"
set :connectstr, "192.168.1.16"

set :mysql_pkg, '/Users/hongbin/tool/mysql/mysql-cluster-advanced-7.2.10-linux2.6-x86_64.tar.gz'
set :realname, File.basename(mysql_pkg,".tar.gz")
set :pkgname, File.basename(mysql_pkg)

set :mysql_root_passwd, 'root'
set :remote_user, 'admin'
set :remote_user_passwd, 'admin'
default_environment['PATH'] = "#{mysql_basedir}/bin:$PATH"

namespace :mysql do
  desc "Upload MySQL Pacakge"
  task :upload_pkg, :roles => [ :sql_hosts, :mgm_hosts, :ndb_hosts ] do
    upload "#{mysql_pkg}", "/tmp", :via => :scp
  end

  desc "Install MySQL Package"
  task :install, :roles => [ :sql_hosts, :mgm_hosts, :ndb_hosts ] do
    [
      "setenforce 0",
      "sed -i.bak 's#SELINUX=enforcing#SELINUX=permissive#g' /etc/selinux/config",
      "grep 'mysql' /etc/passwd || useradd mysql -d /dev/null -s /sbin/nologin",
      "test -d #{prefix} || mkdir -p #{prefix}",
      "tar xzf /tmp/#{pkgname} -C #{prefix}",
      "cd #{prefix} && ln -s #{realname} #{mysql_basedir}",
      "test -d #{data_dir} || mkdir -p #{data_dir}",
      "chown -R mysql: #{data_dir}",
      "echo 'export PATH=#{mysql_basedir}/bin:$PATH' >> /etc/profile"
    ].each {|cmd| run cmd}
  end

  desc "Upgrade MySQL Package"
  task :upgrade, :roles => [ :sql_hosts, :mgm_hosts, :ndb_hosts ] do
    run "tar xzf /tmp/#{pkgname} -C #{prefix}"
    run "cd #{prefix} && unlink #{mysql_basedir}"
    run "cd #{prefix} && ln -s #{realname} #{mysql_basedir}"
  end

  desc "Inital and Start MySQL Server"
  task :initial, :roles => :sql_hosts do
    update
    [
      "rm -rf #{data_dir}/mysql_data/*",
      "cd #{mysql_basedir} && ./scripts/mysql_install_db --force --user=mysql --defaults-file=#{mysql_conf_path} |grep -i ok",
      "cp -f #{mysql_basedir}/support-files/mysql.server /etc/init.d/mysqld",
      "chkconfig --add mysqld"
    ].each {|cmd| run cmd}
  start
  end

  [:start, :stop, :restart, :reload].each do |action|
    desc "#{action.to_s} mysql node"
    task action, :roles => :sql_hosts do
      stream "service mysqld #{t}"
    end
  end

  desc "Kill MySQL process"
  task :kill, :roles => :sql_hosts do
    run "killall -9 mysqld"
  end

  desc "Grant MySQL Privileges admin user "
  task :grant, :roles => :sql_hosts  do
    [
      "mysqladmin -uroot password '#{mysql_root_passwd}'",
      "mysql -uroot -p#{mysql_root_passwd} -e \"SET SQL_LOG_BIN=0;GRANT ALL ON *.* TO #{remote_user}@'%' IDENTIFIED BY '#{remote_user_passwd}'\""
    ].each {|cmd| run cmd}
  end

  desc "Show user on mysql"
  task :user, :roles => :sql_hosts do
    stream "mysql -uroot -p#{mysql_root_passwd} -e 'select user,host from mysql.user'"
  end

  desc "Update MySQL configure"
  task :update, :roles => :sql_hosts do
    # run "test -f #{mysql_conf_path} && mv #{mysql_conf_path}{,_`date +%Y-%m-%d-%H:%M:%S`}"
    upload_template "#{mysql_conf_temp}", "#{mysql_conf_path}"
  end

  desc "Check mysql process alive"
  task :alive, :roles => :sql_hosts do
    run "mysqladmin -u#{remote_user} -p#{remote_user_passwd} -h$CAPISTRANO:HOST$ ping "
  end

  desc "View MySQL error log"
  task :log, :roles => :sql_hosts do
    stream "tailf #{data_dir}/mysql_data/mysql-error.log"
  end

  desc "Grant MySQL Privileges admin user "
  task :grant_repl, :roles => :sql_hosts  do
    run "mysql -uroot -p#{mysql_root_passwd} -e \"GRANT replication client, replication slave ON *.* TO repl@'%' IDENTIFIED BY 'repl'\""
  end

  desc "Setup MySQL Slave Server"
  task :setup_slave, :roles => :mysql_slave  do
    run "mysql -uroot -p#{mysql_root_passwd} -e \"change master to master_host='#{mysql_master}', master_user='repl', master_password='repl'\""
  end

  desc "Add MySQL Instance"
  task :add, :roles => :sql_hosts do
    [
      "test -d #{data_dir}/mysql_data_2 || mkdir -p #{data_dir}/mysql_data_2",
      "cd #{mysql_basedir} && ./scripts/mysql_install_db --user=mysql --datadir=#{data_dir}/mysql_data_2 |grep -i ok",
      "echo 'mysqld --defaults-file=#{mysql_conf_path} --datadir=#{data_dir}/mysql_data_2 --port=3336 --socket=/tmp/mysql_2.sock --user=mysql &' > start_mysql.sh",
      "chmod +x ./start_mysql.sh"
    ].each {|cmd| run cmd}
  end
end
# ==============Management Node Tasks=======================
namespace :mgm do
  desc "Deploy and Start Manger Node"
  task :deploy, :roles => :mgm_hosts do
    run "test -d #{data_dir} || mkdir -p #{data_dir}"
    update
    start
  end

  desc "Start Manage Node"
  task :start, :roles => :mgm_hosts do
    [
      "test -d #{data_dir}/mgm_data || mkdir -p #{data_dir}/mgm_data",
      "ndb_mgmd -f #{mgm_conf_path} --reload --config-cache=0"
    ].each {|cmd| run cmd}
  end

  desc "Stop Manage Node"
  task :stop, :roles => :mgm_hosts do
    stream "ndb_mgm -e '1 stop'", :once => true
  end

  desc "Stop Manage Node"
  task :restart, :roles => :mgm_hosts do
    run "id=`ndb_config -q id --hosts=$CAPISTRANO:HOST$` && ndb_mgm -e '$id restart'"
  end

  desc "Stop MySQL cluster "
  task :shutdown, :roles => :mgm_hosts do
    stream "ndb_mgm -e shutdown", :once => true
  end

  desc "Show Manage status"
  task :show, :roles => :mgm_hosts do
    stream "ndb_mgm -e show", :once => true
  end

  desc "Show MySQL Cluster Memory status"
  task :mem, :roles => :mgm_hosts do
    stream "ndb_mgm -e 'all report mem'", :once => true
  end

  desc "View Manage Node log"
  task :log, :roles => :mgm_hosts do
    stream "tailf #{data_dir}/mgm_data/ndb_*_cluster.log", :once => true
  end

  desc "Update MySQL Cluster Configure File"
  task :update, :roles => :mgm_hosts do
    # run "DATE=`date +%Y-%m-%d-%H:%M:%S` && mv #{mgm_conf_path}{,_$DATE}"
    upload_template "#{mgm_conf_temp}", "#{mgm_conf_path}"
  end
end

# ==============Data Node Tasks=======================
namespace :ndb do
  desc "Deploy and Initial Data Node"
  task :initial, :roles => :ndb_hosts do
    [
      "test -d #{data_dir}/ndb_data || mkdir -p #{data_dir}/ndb_data",
      "ndbmtd -c #{connectstr} --initial"
    ].each {|cmd| run cmd}
  end

  desc "Start Data Node"
  task :start, :roles => :ndb_hosts do
    run "ndbmtd -c #{connectstr} "
  end

  desc "Stop Data Node"
  task :stop, :roles => :ndb_hosts do
    run "id=`ndb_config -c #{connectstr} -q id --hosts=$CAPISTRANO:HOST$` && ndb_mgm -c #{connectstr} -e '$id stop'"
  end

  desc "Stop Data Node"
  task :restart, :roles => :ndb_hosts do
    run "id=`ndb_config -c #{connectstr} -q id --hosts=$CAPISTRANO:HOST$` && ndb_mgm -c #{connectstr} -e '$id restart'"
  end

  desc "Show Data Node status"
  task :status, :roles => :mgm_hosts do
    stream "ndb_mgm -e 'all status'", :once => true
  end
  desc "Kill Data Node process"
  task :kill, :roles => :ndb_hosts do
    run "kill -9 ndbmtd"
  end

  desc "View Data Node log"
  task :log, :roles => :ndb_hosts do
    stream "tailf #{data_dir}/ndb_data/ndb_*_out.log"
  end
end
