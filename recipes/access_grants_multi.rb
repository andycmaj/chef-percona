# vim: set ts=2 sw=2 tw=2 :

passwords = EncryptedPasswords.new(node, node["percona"]["encrypted_data_bag"])

# define access grants
template "/etc/mysql/grants.sql" do
  source "grants.sql.erb"
  action :create_if_missing
  variables(
    :root_password => passwords.root_password
  )
end

node["instance_ports"].each do |port|
  datadir = node["percona"]["server"]["datadir"] % { :port => port }
  if File.exists?(datadir)
    log "Already exists: #{port}"
    tag(port)
    next
  end

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
    end
  else
    # Simpler path...  just try running the grants command
    execute "mysql-install-privileges" do
      command "/usr/bin/mysql -h127.0.0.1 -P#{port} < /etc/mysql/grants.sql"
    end
  end

end
