# vim: set ts=2 sw=2 tw=2 :

instance_ports = node["instance_ports"]
instance_ports.each do |port|
  datadir = server["datadir"] % { :port => port }
  if File.exists?(datadir)
    log "Already exists: #{port}"
    tag(port)
    next
  end

  # setup the data directory
  directory datadir do
    owner user
    group user
    recursive true
    action :create
  end

  # setup the main server config file
  # For multiple instances of mysql.%{port}, place the cnf file in the (deprecated) datadir.
  template "#{datadir}/my.cnf" do
    source "my.cnf.multi_instance.erb"
    variables :port => port
    owner "root"
    group "root"
    mode 0744
  end

  # install db to the data directory
  execute "setup mysql datadir" do
    command "mysql_install_db --user=#{user} --datadir=#{datadir}"
    not_if "test -f #{datadir}/mysql/user.frm"
  end

  # define service name
  serviceName = "mysql.#{port}"

  # create service
  template "/etc/init.d/#{serviceName}" do
    source "init.d.mysql.erb"
    variables :data_dir => datadir, :port => port
    owner user
    group user
    mode 0755
  end

  # install and start the service
  service serviceName do
    supports :restart => true, :reload => true
    action [ :enable, :start ]
  end

  # now let's set the root password only if this is the initial install
  execute "Update MySQL root password" do
    command "mysqladmin --host=127.0.0.1 --port=#{port} --user=root --password='' password '#{passwords.root_password}'"
  end
end

# stop the default mysql instance.
service "mysql" do
  action [ :stop, :disable ]
end
