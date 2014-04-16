# vim: set ts=2 sw=2 tw=2 :

passwords = EncryptedPasswords.new(node, node["percona"]["encrypted_data_bag"])

# define access grants
template "/etc/mysql/grants.sql" do
  source "grants.sql.erb"
  variables(
    :root_password        => passwords.root_password,
    :debian_user          => node["percona"]["server"]["debian_username"],
    :debian_password      => passwords.debian_password,
    :backup_password      => passwords.backup_password
  )
  owner "root"
  group "root"
  mode "0600"
end

instance_ports = node["instance_ports"]
instance_ports.each do |port|

  # execute access grants
  if passwords.root_password && !passwords.root_password.empty?
    # Intent is to check whether the root_password works, and use it to
    # load the grants if so.  If not, try loading without a password
    # and see if we get lucky
    execute "mysql-install-privileges" do
      command "/usr/bin/mysql -h127.0.0.1 -P#{port} -p'" + passwords.root_password + \
          "' -e '' &> /dev/null > /dev/null &> /dev/null ; if [ $? -eq 0 ] ; " + \
          "then /usr/bin/mysql -h127.0.0.1 -P#{port} -p'" + passwords.root_password + \
          "' < /etc/mysql/grants.sql ; else /usr/bin/mysql -h127.0.0.1 -P#{port} < /etc/mysql/grants.sql ; fi ;"
      action :nothing
      subscribes :run, resources("template[/etc/mysql/grants.sql]"), :immediately
    end
  else
    # Simpler path...  just try running the grants command
    execute "mysql-install-privileges" do
      command "/usr/bin/mysql -h127.0.0.1 -P#{port} < /etc/mysql/grants.sql"
      action :nothing
      subscribes :run, resources("template[/etc/mysql/grants.sql]"), :immediately
    end
  end

end
