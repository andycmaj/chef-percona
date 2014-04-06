case node["platform_family"]
when "debian"
  normal['mysql']['client']['packages'] = %w{libmysqlclient-dev percona-server-client-5.6}
when "rhel"
  normal['mysql']['client']['packages'] = %w{Percona-Server-client-56}
end
