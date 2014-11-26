if ['app_master', 'app'].include?(node[:instance_role])


  # at the time of writing we only have ONE server with a role of app
  # if we add more app servers then we will need to figure out how to pick up the correct redis server
  # we could remove the slave and create a utility instance as they can be named
  # DM - 26/11/14

  redis_hostname = node[:engineyard][:environment][:instances].find{|i| i[:role] == 'app' }[:public_hostname]

  # Otherwise, if you have multiple utility instances you can specify it by uncommenting the line below
  # You can change the name of the instance based on whatever name you have chosen for your instance.
  #redis_instance = node['utility_instances'].find { |instance| instance['name'] == 'redis' }

  if redis_hostname
    node[:applications].each do |app, data|
      template "/data/#{app}/shared/config/redis.yml"do
        source 'redis.yml.erb'
        owner node[:owner_name]
        group node[:owner_name]
        mode 0655
        backup 0
        variables({
          :environment => node[:environment][:framework_env],
          :hostname => redis_hostname
        })
      end
    end
  end
end