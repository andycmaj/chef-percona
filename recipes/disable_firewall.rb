# vim: set ts=2 sw=2 tw=2 :

if node["percona"]["server"]["disable_firewall"]
  %w{iptables ip6tables}.each do |service_name|
    service service_name do
      action [ :stop ]
    end
  end
end
