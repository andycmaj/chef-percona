include_recipe "percona::package_repo"

# install packages
# Need to remove this to avoid conflicts
package "mysql-libs" do
  action :remove
  not_if "rpm -qa | grep #{node['percona']['server']['shared_pkg']}"
end

# we need mysqladmin
include_recipe "percona::client"

# install percona server
package node["percona"]["server"]["package"] do
  action :install
end

include_recipe "percona::cleanup_unused_instances"

include_recipe "percona::configure_multi_instance_server"

# access grants for remote access
# unless node["percona"]["skip_passwords"]
#   include_recipe "percona::access_grants_multi"
# end

# disable firewall on server
if node["percona"]["server"]["disable_firewall"]
  include_recipe "percona::disable_firewall"
end
