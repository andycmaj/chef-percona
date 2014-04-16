# vim: set ts=2 sw=2 tw=2 :

percona = node["percona"]
server  = percona["server"]
conf    = percona["conf"]
mysqld  = (conf && conf["mysqld"]) || {}

# TODO: factor common actions into common configure recipe.
# construct an encrypted passwords helper -- giving it the node and bag name
passwords = EncryptedPasswords.new(node, percona["encrypted_data_bag"])

template "/root/.my.cnf" do
  variables(:root_password => passwords.root_password)
  owner "root"
  group "root"
  mode 0600
  source "my.cnf.root.erb"
end

if server["bind_to"]
  ipaddr = Percona::ConfigHelper.bind_to(node, server["bind_to"])
  if ipaddr && server["bind_address"] != ipaddr
    node.override["percona"]["server"]["bind_address"] = ipaddr
    node.save unless Chef::Config[:solo]
  end

  log "Can't find ip address for #{server["bind_to"]}" do
    level :warn
    only_if { ipaddr.nil? }
  end
end

# this is where we dump sql templates for replication, etc.
directory "/etc/mysql" do
  owner "root"
  group "root"
  mode 0755
end


tmpdir = mysqld["tmpdir"] || server["tmpdir"]
user   = mysqld["username"] || server["username"]

# setup the tmp directory
directory tmpdir do
  owner user
  group user
  recursive true
  action :create
end

instance_ports = node["instance_ports"]
# TODO: default to just 3306 when instance_ports is null or empty

instance_ports.each do |port|
  datadir = ( mysqld["datadir"] || server["datadir"] ) % { :port => port }
  if File.exists?(datadir)
    log "Already tagged: #{datadir}"
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
  configFile = datadir + "/my.cnf"
  template configFile do
    source "my.cnf.#{conf ? "custom" : server["role"]}.erb"
    variables :port => port
    owner "root"
    group "root"
    mode 0744
    # notifies :reload, "service[mysqld_multi]", :immediately if node["percona"]["auto_restart"]
  end

  # install db to the data directory
  execute "setup mysql datadir" do
    command "mysql_install_db --user=#{user} --datadir=#{datadir}"
    not_if "test -f #{datadir}/mysql/user.frm"
  end

  serviceName = "mysql.#{port}"

  template "/etc/init.d/#{serviceName}" do
    source "init.d.mysql.erb"
    variables :data_dir => datadir, :port => port
    owner user
    group user
    mode 0755
  end

  # define the service
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

# TODO: loop through node[:tags] and remove instances that arent in instance_ports
