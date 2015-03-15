#
# array_or_string_to_array.rb
#

module Puppet::Parser::Functions
  newfunction(:nodes_to_hosts, :type => :rvalue, :doc => <<-EOS
              convert nodes array passed from Astute into
              hash for puppet `host` create_resources call
    EOS
  ) do |args|
    hosts=Hash.new
    nodes=args[0]
    nodes.each do |node|
      if node['role'] == 'ceph-osd' or node['role'] == 'ceph-mon' or node['role'] == 'primary-ceph-mon'
        address = 'storage_address'
       else
        address = 'internal_address'
      end
      hosts[node['fqdn']]={:ip=>node[address],:host_aliases=>[node['name']]}
      notice("Generating host entry #{node['name']} #{node[address]} #{node['fqdn']}")
    end
    return hosts
  end
end

# vim: set ts=2 sw=2 et :
