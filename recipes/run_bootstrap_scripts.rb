# vim: set ts=2 sw=2 tw=2 :

passwords = EncryptedPasswords.new(node, node["percona"]["encrypted_data_bag"])

node["instance_ports"].each do |port|
  next if tagged?(port)

  node["db_bootstrappers"].each { |bootstrapper_glob|
    Dir.glob(bootstrapper_glob).each { |file|

      execute file do
        command "/usr/bin/mysql -h127.0.0.1 -P#{port} -uroot -p'" \
          + passwords.root_password \
          + "' < #{file}"
        retries 3
        retry_delay 10
      end

    }
  }

end

