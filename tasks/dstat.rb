require File.expand_path(File.dirname(__FILE__) + '/utilities')

namespace :dstat do
  desc "Install dstat "
  task :install do
    yum_install "dstat"
  end
  desc "Monitor hosts with dstat"
  task :monitor do
    stream "dstat --time --cpu --mem --disk --net --proc --page --swap --load --noheaders --output /tmp/dstat.csv 10 90 "
  end
end
