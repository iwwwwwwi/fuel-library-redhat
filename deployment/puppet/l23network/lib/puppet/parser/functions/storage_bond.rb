# 
# storage_bond.rb 
# 
require 'ipaddr'
begin
  require 'puppet/parser/functions/lib/prepare_cidr.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See 
  # # #4248). It should (in the future) but for the time being we need to be 
  # # defensive which is what this rescue block is doing. 
  rb_file = File.join(File.dirname(__FILE__),'lib','prepare_cidr.rb')
  load rb_file if File.exists?(rb_file) or raise e
end
begin
  require 'puppet/parser/functions/lib/l23network_scheme.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See 
  #4248). It should (in the future) but for the time being we need to be 
  # defensive which is what this rescue block is doing. 
  rb_file = File.join(File.dirname(__FILE__),'lib','l23network_scheme.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

module Puppet::Parser::Functions
  newfunction(:storage_bond, :type => :rvalue, :doc => <<-EOS
This function get classic netmask and returns cidr masklen. 
EOS
  ) do |arguments|

    bridge = arguments[0]
    cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
    iface = cfg[:transformations].find {|i| i.has_key?(:bridges) and i[:bridges].include?(bridge) }[:bridges].find {|b| b != bridge}
    return iface
  end
end

