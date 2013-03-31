require File.expand_path(File.dirname(__FILE__) + '/utilities')


namespace :sysbench do
  Dir.mkdir("benchmark_results") unless File.exist?("benchmark_results")
  set :sysbench_pkg, '/Users/hongbin/tool/sysbench-0.5.tar.gz'

  desc "Build benchmark tool sysbench"
  task :install do
    upload "#{sysbench_pkg}", "/tmp/sysbench.tar.gz", :via => :scp
    [
      "tar xzf /tmp/sysbench.tar.gz -C /usr/local",
      # "cd /usr/local/sysbench && ./autogen.sh",
      "cd /usr/local/sysbench && ./configure",
      "cd /usr/local/sysbench && make && make install"
    ].each {|cmd| run cmd}
  end

  desc "Benchmark H/W Disk IO"
  task :io do
    [
      "sysbench --num-threads=16 --test=fileio --file-total-size=3G --file-test-mode=rndrw prepare",
      "sysbench --num-threads=16 --test=fileio --file-total-size=3G --file-test-mode=rndrw run > /tmp/bench_disk",
      "sysbench --num-threads=16 --test=fileio --file-total-size=3G --file-test-mode=rndrw cleanup"
    ].each {|cmd| run cmd}
    download "/tmp/bench_disk", "benchmark_results/bench_disk_$CAPISTRANO:HOST$"
  end

  desc "Benchmark H/W CPU Speed"
  task :cpu do
    run "sysbench --test=cpu --cpu-max-prime=10000 run > /tmp/bench_cpu"
    download "/tmp/bench_cpu", "benchmark_results/bench_cpu_$CAPISTRANO:HOST$"
  end

  desc "Benchmark H/W Memory"
  task :mem do
    run "sysbench --test=memory run > /tmp/bench_mem"
    download "/tmp/bench_mem", "benchmark_results/bench_mem_$CAPISTRANO:HOST$"
  end

  desc "Benchmark H/W Memory"
  task :collect do
    download "sysbench_result", "sysbench_result_$CAPISTRANO:HOST$"
  end
end

# awk 'BEGIN {printf "%s%5s%15s%15s\n", "Connect","TPS","QPS","RT"}; {if ($0 ~ /threads:/){printf "%s\t", $4} ;if ($0 ~/transactions:/){sub(/\(/,"");printf "%s\t", $3};if($0~/requests:/){sub(/\(/,"");printf "%s\t",$4};if ($0~/avg:/){print $2}}'