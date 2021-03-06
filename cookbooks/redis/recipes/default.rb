#
# Cookbook Name:: redis
# Recipe:: default
#

if ['app'].include?(node[:instance_role])
  # if node[:name] == 'redis'

    sysctl "Enable Overcommit Memory" do
      variables 'vm.overcommit_memory' => 1
    end

    enable_package "dev-db/redis" do
      version "2.4.6"
    end

    package "dev-db/redis" do
      version "2.4.6"
      action :upgrade
    end

    directory "#{node[:redis][:basedir]}" do
      owner 'redis'
      group 'redis'
      mode 0755
      recursive true
      action :create
    end

    template "/etc/redis_util.conf" do
      owner 'root'
      group 'root'
      mode 0644
      source "redis.conf.erb"
      variables({
        :pidfile => node[:redis][:pidfile],
        :basedir => node[:redis][:basedir],
        :basename => node[:redis][:basename],
        :logfile => node[:redis][:logfile],
        :loglevel => node[:redis][:loglevel],
        :port  => node[:redis][:bindport],
        :unixsocket => node[:redis][:unixsocket],
        :saveperiod => node[:redis][:saveperiod],
        :timeout => node[:redis][:timeout],
        :databases => node[:redis][:databases],
        :rdbcompression => node[:redis][:rdbcompression],
      })
    end

    # redis-server is in /usr/bin on stable-v2, /usr/sbin for stable-v4
    if Chef::VERSION[/^0.6/]
      bin_path = "/usr/bin/redis-server"
    else
      bin_path = "/usr/sbin/redis-server"
    end

    template "/data/monit.d/redis_util.monitrc" do
      owner 'root'
      group 'root'
      mode 0644
      source "redis.monitrc.erb"
      variables({
        :profile => '1',
        :configfile => '/etc/redis_util.conf',
        :pidfile => node[:redis][:pidfile],
        :logfile => node[:redis][:basename],
        :port => node[:redis][:bindport],
        :bin_path => bin_path
      })
    end

    execute "monit reload" do
      action :run
    end
  # end
end

if ['solo', 'app', 'app_master', 'db_master'].include?(node[:instance_role])
  instances = node[:engineyard][:environment][:instances]
  redis_instance = instances.find{|i| i[:role] == 'app' }

  if redis_instance
    ip_address = `ping -c 1 #{redis_instance[:private_hostname]} | awk 'NR==1{gsub(/\\(|\\)/,"",$3); print $3}'`.chomp
    host_mapping = "#{ip_address} redis_instance"

    execute "Remove existing redis_instance mapping from /etc/hosts" do
      command "sudo sed -i '/redis_instance/d' /etc/hosts"
      action :run
    end

    execute "Add redis_instance mapping to /etc/hosts" do
      command "sudo echo #{host_mapping} >> /etc/hosts"
      action :run
    end
  end
end
