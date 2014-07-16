# vim: set ts=2 sw=2 tw=2 :
require 'fileutils'

instance_ports = node["instance_ports"]
datadir_root = node["percona"]["server"]["datadir_root"]

if Dir.exist?(datadir_root)
  Dir.chdir(datadir_root)
  instance_dirs = Dir['*/']

  instance_dirs.each do |dir|
    port = File.basename(dir)
    if instance_ports.include?(port.to_i)
      log "Keeping instance: #{port}"
      next
    end

    log "Deleting instance #{port}"

    # define service name
    serviceName = "mysql.#{port}"

    # stop and delete service
    service serviceName do
      action [ :disable, :stop ]
    end

    file "/etc/init.d/#{serviceName}" do
      action :delete
    end

    # delete datadir
    directory dir do
      action :delete
      recursive true
    end
  end
end
