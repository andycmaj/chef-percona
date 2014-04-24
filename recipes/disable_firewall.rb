# vim: set ts=2 sw=2 tw=2 :

%w{iptables ip6tables}.each do |service_name|
  service service_name do
    action [ :stop ]
  end
end
