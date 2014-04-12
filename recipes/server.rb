include_recipe "percona::package_repo"

# install packages
case node["platform_family"]
when "debian"
  package node["percona"]["server"]["package"] do
    action :install
    options "--force-yes"
  end
when "rhel"
  # Need to remove this to avoid conflicts
  package "mysql-libs" do
    action :remove
    not_if "rpm -qa | grep #{node['percona']['server']['shared_pkg']}"
  end

  # we need mysqladmin
  include_recipe "percona::client"

  package node["percona"]["server"]["package"] do
    action :install
  end
end


include_recipe node["percona"]["server"]["role"] == "multi_instance" ? "percona::configure_multi_instance_server" : "percona::configure_server"

# access grants
unless node["percona"]["skip_passwords"]
  include_recipe "percona::access_grants"
end

unless node["percona"]["skip_passwords"]
  include_recipe "percona::replication"
end
