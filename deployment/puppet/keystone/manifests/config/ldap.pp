#
# This class implements a config fragment for
# the ldap specific backend for keystone.
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::ldap(
  $url            = 'ldap://localhost',
  $user           = 'dc=Manager,dc=example,dc=com',
  $password       = 'None',
  $suffix         = 'cn=example,cn=com',
  $user_tree_dn   = 'ou=Users,dc=example,dc=com',
  $tenant_tree_dn = 'ou=Roles,dc=example,dc=com',
  $role_tree_dn   = 'dc=example,dc=com'
) {

  keystone_config {
    'ldap/url':            value => $url;
    'ldap/user':           value => $user;
    'ldap/password':       value => $password;
    'ldap/suffix':         value => $suffix;
    'ldap/user_tree_dn':   value => $user_tree_dn;
  }
}

class keystone::config::ldap(
  $url            = $::fuel_settings['keystone_ldap']['ldap_url'],
  $suffix         = $::fuel_settings['keystone_ldap']['ldap_suffix'],
  $user           = $::fuel_settings['keystone_ldap']['ldap_user'],
  $password       = $::fuel_settings['keystone_ldap']['ldap_pass'],
  $user_tree_dn   = $::fuel_settings['keystone_ldap']['ldap_user_tree_dn'],

#  $url            = 'ldap://172.16.49.136',
#  $suffix         = 'dc=caponelab,dc=local',
#  $user           = 'cn=svcadmindev,ou=Engineering,dc=caponelab,dc=local', 
#  $password       = 'admin',
#  $user_tree_dn   = 'ou=Engineering,dc=caponelab,dc=local',

  $user_enabled_attribute = 'userAccountControl',
  $ldap_driver    = 'keystone.identity.backends.ldap.Identity',
  $assignment_driver    = 'keystone.assignment.backends.sql.Assignment',
) {

  if ! defined(Package['python-ldap']) {
    package { 'python-ldap': ensure => installed, }
    package { 'python-ldappool': ensure => installed, }

    Package['python-ldap'] -> Package['python-ldappool'] -> Keystone_config<||>
  }

  keystone_config {
    'ldap/url':				value => $url;
    'ldap/suffix':			value => $suffix;
    'ldap/user':			value => "'${user}'";
    'ldap/password':			value => $password;
    'ldap/user_tree_dn':		value => "'${user_tree_dn}'";
    'ldap/user_objectclass':		value => 'person';
    'ldap/user_id_attribute':		value => 'cn';
    'ldap/user_filter':   		value => '(cn=svc*prd)';
    'ldap/user_name_attribute':		value => 'cn';
    'ldap/user_mail_attribute':		value => 'mail';
    'ldap/user_pass_attribute':		value => '';
    'ldap/user_enabled_mask':		value => '2';
    'ldap/user_enabled_default':	value => '512';
    'ldap/user_attribute_ignored':	value => 'tenant_id,tenants';
    'ldap/user_allow_create':   	value => 'False';
    'ldap/user_allow_update':   	value => 'False';
    'ldap/user_allow_delete':   	value => 'False';
    'ldap/user_enabled_attribute':	value => "'${user_enabled_attribute}'";
    'identity/driver':			value => $ldap_driver;
    'assignment/driver':		value => $assignment_driver;
    'ldap/query_scope':     value => 'sub';
    'ldap/page_size':       value => '1000';
  }
}
