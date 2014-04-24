name              "percona"
maintainer        "Andy Cunningham"
maintainer_email  "andycunn@gmail.com"
license           "Apache 2.0"
description       "Installs multi-instance Percona MySQL client and server"
long_description  "Please refer to README.md"
version           "0.14.5"

recipe "percona",                "Includes the client recipe to configure a client"
recipe "percona::package_repo",  "Sets up the package repository and installs dependent packages"
recipe "percona::client",        "Installs client libraries"
recipe "percona::server",        "Installs the server daemon"
recipe "percona::configure_multi_instance_server", "Used internally to manage the server configuration."
recipe "percona::access_grants_multi", "Used internally to grant permissions for recipes"

depends "apt", ">= 1.9"
depends "yum", "~> 3.0"
depends "openssl"
depends "mysql", "~> 3.0"

%w[centos amazon fedora redhat].each do |os|
  supports os
end
