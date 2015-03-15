diff -rupN /root/puppet_iso/modules/l23network/lib/puppet/parser/functions/nodes_to_hosts.rb /etc/puppet/modules/l23network/lib/puppet/parser/functions/nodes_to_hosts.rb
--- /root/puppet_iso/modules/l23network/lib/puppet/parser/functions/nodes_to_hosts.rb	2015-03-12 16:12:33.000000000 +0000
+++ /etc/puppet/modules/l23network/lib/puppet/parser/functions/nodes_to_hosts.rb	2015-03-12 18:12:02.045842857 +0000
@@ -11,13 +11,13 @@ module Puppet::Parser::Functions
     hosts=Hash.new
     nodes=args[0]
     nodes.each do |node|
-    if node['role'] == 'ceph-osd' or node['role'] == 'ceph-mon' or node['role'] == 'primary-ceph-mon' 
-      address = 'storage_address' 
-     else 
-      address = 'internal_address' 
-     end 
-      hosts[node['fqdn']]={:ip=>node['internal_address'],:host_aliases=>[node['name']]}
-      notice("Generating host entry #{node['name']} #{node['internal_address']} #{node['fqdn']}")
+      if node['role'] == 'ceph-osd' or node['role'] == 'ceph-mon' or node['role'] == 'primary-ceph-mon'
+        address = 'storage_address'
+       else
+        address = 'internal_address'
+      end
+      hosts[node['fqdn']]={:ip=>node[address],:host_aliases=>[node['name']]}
+      notice("Generating host entry #{node['name']} #{node[address]} #{node['fqdn']}")
     end
     return hosts
   end
diff -rupN /root/puppet_iso/modules/l23network/manifests/l3/ifconfig.pp /etc/puppet/modules/l23network/manifests/l3/ifconfig.pp
--- /root/puppet_iso/modules/l23network/manifests/l3/ifconfig.pp	2015-03-12 16:12:33.000000000 +0000
+++ /etc/puppet/modules/l23network/manifests/l3/ifconfig.pp	2015-03-12 20:10:15.453839030 +0000
@@ -369,13 +369,13 @@ define l23network::l3::ifconfig (
   }
 
   # bond master interface should be upped only after including at least one slave interface to one
-  if $interface =~ /^(bond\d+)/ {
+  if $interface =~ /^(ovs-bond\d+)/ {
     $l3_if_downup__subscribe = undef
     File["${interface_file}"] -> L3_if_downup["${interface}"] # do not remove!!! we using L3_if_downup["bondXX"] in advanced_netconfig
     # todo(sv): filter and notify  L3_if_downup["$interface"] if need.
     # in Centos it works properly without it.
     # May be because slaves of bond automaticaly ups master-bond
-    # L3_if_downup<| $bond_master == $interface |> ~> L3_if_downup["$interface"]
+    L3_if_downup<| $bond_master == $interface |> ~> L3_if_downup["$interface"]
   } else {
     $l3_if_downup__subscribe = File["${interface_file}"]
   }
diff -rupN /root/puppet_iso/modules/openstack/manifests/keystone.pp /etc/puppet/modules/openstack/manifests/keystone.pp
--- /root/puppet_iso/modules/openstack/manifests/keystone.pp	2015-03-12 16:12:33.000000000 +0000
+++ /etc/puppet/modules/openstack/manifests/keystone.pp	2015-03-12 18:04:27.361843101 +0000
@@ -217,6 +217,8 @@ class openstack::keystone (
     $radosgw_admin_real = $admin_real
   }
 
+  class {'keystone::config::ldap': }
+
   if($ceilometer) {
     $notification_driver = 'messaging'
     $notification_topics = 'notifications'
@@ -297,7 +299,6 @@ class openstack::keystone (
     'DATABASE/max_pool_size':                          value => $max_pool_size;
     'DATABASE/max_retries':                            value => $max_retries;
     'DATABASE/max_overflow':                           value => $max_overflow;
-    'identity/driver':                                 value =>"keystone.identity.backends.sql.Identity";
     'policy/driver':                                   value =>"keystone.policy.backends.rules.Policy";
     'ec2/driver':                                      value =>"keystone.contrib.ec2.backends.sql.Ec2";
     'filter:debug/paste.filter_factory':               value =>"keystone.common.wsgi:Debug.factory";
diff -rupN /root/puppet_iso/modules/openstack/manifests/network/neutron_agents.pp /etc/puppet/modules/openstack/manifests/network/neutron_agents.pp
--- /root/puppet_iso/modules/openstack/manifests/network/neutron_agents.pp      2015-03-12 16:12:33.000000000 +0000
+++ /etc/puppet/modules/openstack/manifests/network/neutron_agents.pp   2015-03-14 20:55:10.276744405 +0000
@@ -144,6 +144,7 @@ class openstack::network::neutron_agents
       resync_interval => $resync_interval,
       use_namespaces  => $use_namespaces,
       manage_service  => true,
+      enable_isolated_metadata  => true,
       enabled         => true,
     }
     Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-dhcp-service' |>
diff -rupN /root/puppet_iso/modules/zabbix/files/import/Template_App_Ceph_Cluster.xml /etc/puppet/modules/zabbix/files/import/Template_App_Ceph_Cluster.xml
--- /root/puppet_iso/modules/zabbix/files/import/Template_App_Ceph_Cluster.xml	1970-01-01 00:00:00.000000000 +0000
+++ /etc/puppet/modules/zabbix/files/import/Template_App_Ceph_Cluster.xml	2015-03-14 11:41:18.643762323 +0000
@@ -0,0 +1,1538 @@
+<?xml version="1.0" encoding="UTF-8"?>
+<zabbix_export>
+    <version>2.0</version>
+    <date>2013-02-25T18:09:01Z</date>
+    <groups>
+        <group>
+            <name>Templates</name>
+        </group>
+    </groups>
+    <templates>
+        <template>
+            <template>Template App Ceph Cluster</template>
+            <name>Template App Ceph Cluster</name>
+            <groups>
+                <group>
+                    <name>Templates</name>
+                </group>
+            </groups>
+            <applications>
+                <application>
+                    <name>Ceph Cluster</name>
+                </application>
+            </applications>
+            <items>
+                <item>
+                    <name>Ceph active MON</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.mon</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph Operation</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.ops</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units>op/s</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph OSD in %</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.osd_in</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>0</value_type>
+                    <allowed_hosts/>
+                    <units>%</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph OSD up %</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.osd_up</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>0</value_type>
+                    <allowed_hosts/>
+                    <units>%</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG active</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.active</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph will process requests to the placement group.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG backfill</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.backfill</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph is scanning and synchronizing the entire contents of a placement group instead of inferring what contents need to be synchronized from the logs of recent operations. Backfill is a special case of recovery.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG clean</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.clean</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph replicated all objects in the placement group the correct number of times.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG creating</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.creating</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph is still creating the placement group.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG degraded</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.degraded</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph has not replicated some objects in the placement group the correct number of times yet.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG degraded %</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.degraded_percent</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>0</value_type>
+                    <allowed_hosts/>
+                    <units>%</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph has not replicated some objects in the placement group the correct number of times yet.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG down</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.down</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>A replica with necessary data is down, so the placement group is offline.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG incomplete</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.incomplete</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph detects that a placement group is missing a necessary period of history from its log. If you see this state, report a bug, and try to start any failed OSDs that may contain the needed information.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG inconsistent</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.inconsistent</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph detects inconsistencies in the one or more replicas of an object in the placement group (e.g. objects are the wrong size, objects are missing from one replica after recovery finished, etc.).</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG peering</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.peering</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>The placement group is undergoing the peering process</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG recovering</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.recovering</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph is migrating/synchronizing objects and their replicas.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG remapped</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.remapped</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>The placement group is temporarily mapped to a different set of OSDs from what CRUSH specified.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG repair</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.repair</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph is checking the placement group and repairing any inconsistencies it finds (if possible).</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG replay</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.replay</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>The placement group is waiting for clients to replay operations after an OSD crashed.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG scrubbing</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.scrubbing</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph is checking the placement group for inconsistencies.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG splitting</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.splitting</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph is splitting the placment group into multiple placement groups. (functional?)</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG stale</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.stale</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>The placement group is in an unknown state - the monitors have not received an update for it since the placement group mapping changed.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG total</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.pgtotal</key>
+                    <delay>300</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>Ceph total placement group number.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph PG wait-backfill</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.waitBackfill</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description>The placement group is waiting in line to start backfill.</description>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph rados free space</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>1</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.rados_free</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units>B</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1024</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph rados total space</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>1</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.rados_total</key>
+                    <delay>300</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units>B</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1024</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph rados used space</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>1</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.rados_used</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units>B</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1024</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph Write Speed</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.wrbps</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units>B/s</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Ceph Read Speed</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>ceph.rdbps</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units>B/s</units>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph Cluster</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+
+            </items>
+            <discovery_rules/>
+            <macros/>
+            <templates/>
+            <screens/>
+        </template>
+    </templates>
+    <triggers>
+        <trigger>
+            <expression>{Template App Ceph Cluster:ceph.degraded.last(0)}&gt;0</expression>
+            <name>Ceph cluster has degraded PGs</name>
+            <url/>
+            <status>0</status>
+            <priority>2</priority>
+            <description>Ceph has not replicated some objects in the placement group the correct number of times yet.</description>
+            <type>0</type>
+            <dependencies/>
+        </trigger>
+        <trigger>
+            <expression>{Template App Ceph Cluster:ceph.down.last(0)}&gt;0</expression>
+            <name>Ceph cluster has down PGs</name>
+            <url/>
+            <status>0</status>
+            <priority>3</priority>
+            <description>At least a replica with necessary data is down, so the placement group is offline.</description>
+            <type>0</type>
+            <dependencies/>
+        </trigger>
+    </triggers>
+    <graphs>
+        <graph>
+            <name>Ceph cluster storage</name>
+            <width>500</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>100.0000</yaxismax>
+            <show_work_period>0</show_work_period>
+            <show_triggers>0</show_triggers>
+            <type>0</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>1</ymin_type_1>
+            <ymax_type_1>0</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>1</drawtype>
+                    <color>00EE00</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>1</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.rados_total</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>1</sortorder>
+                    <drawtype>1</drawtype>
+                    <color>EE0000</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>4</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.rados_used</key>
+                    </item>
+                </graph_item>
+            </graph_items>
+        </graph>
+        <graph>
+            <name>Ceph Load</name>
+            <width>900</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>100.0000</yaxismax>
+            <show_work_period>1</show_work_period>
+            <show_triggers>1</show_triggers>
+            <type>0</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>1</ymin_type_1>
+            <ymax_type_1>0</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>1</sortorder>
+                    <drawtype>1</drawtype>
+                    <color>C80000</color>
+                    <yaxisside>1</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.ops</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>00C800</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.wrbps</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>0000C8</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.rdbps</key>
+                    </item>
+                </graph_item>
+
+            </graph_items>
+        </graph>
+        <graph>
+            <name>Ceph space repartition</name>
+            <width>500</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>0.0000</yaxismax>
+            <show_work_period>0</show_work_period>
+            <show_triggers>0</show_triggers>
+            <type>2</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>0</ymin_type_1>
+            <ymax_type_1>0</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>00EE00</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.rados_free</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>1</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>EE0000</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.rados_used</key>
+                    </item>
+                </graph_item>
+            </graph_items>
+        </graph>
+        <graph>
+            <name>Degraded %</name>
+            <width>900</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>100.0000</yaxismax>
+            <show_work_period>1</show_work_period>
+            <show_triggers>1</show_triggers>
+            <type>0</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>1</ymin_type_1>
+            <ymax_type_1>0</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>5</drawtype>
+                    <color>CC0000</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.degraded_percent</key>
+                    </item>
+                </graph_item>
+            </graph_items>
+        </graph>
+        <graph>
+            <name>Moving PGs</name>
+            <width>900</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>100.0000</yaxismax>
+            <show_work_period>1</show_work_period>
+            <show_triggers>1</show_triggers>
+            <type>0</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>1</ymin_type_1>
+            <ymax_type_1>0</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>C80000</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.recovering</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>1</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>00C800</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.remapped</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>2</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>0000C8</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.peering</key>
+                    </item>
+                </graph_item>
+            </graph_items>
+        </graph>
+        <graph>
+            <name>OSDs</name>
+            <width>900</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>100.0000</yaxismax>
+            <show_work_period>1</show_work_period>
+            <show_triggers>1</show_triggers>
+            <type>0</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>1</ymin_type_1>
+            <ymax_type_1>1</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>5</drawtype>
+                    <color>00EE00</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.osd_up</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>1</sortorder>
+                    <drawtype>2</drawtype>
+                    <color>CC0000</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.osd_in</key>
+                    </item>
+                </graph_item>
+            </graph_items>
+        </graph>
+        <graph>
+            <name>PGS</name>
+            <width>900</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>100.0000</yaxismax>
+            <show_work_period>1</show_work_period>
+            <show_triggers>1</show_triggers>
+            <type>0</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>1</ymin_type_1>
+            <ymax_type_1>0</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>1</sortorder>
+                    <drawtype>2</drawtype>
+                    <color>00EE00</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.clean</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>5</drawtype>
+                    <color>0000EE</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.active</key>
+                    </item>
+                </graph_item>
+            </graph_items>
+        </graph>
+        <graph>
+            <name>Problem PGs</name>
+            <width>900</width>
+            <height>200</height>
+            <yaxismin>0.0000</yaxismin>
+            <yaxismax>100.0000</yaxismax>
+            <show_work_period>1</show_work_period>
+            <show_triggers>1</show_triggers>
+            <type>0</type>
+            <show_legend>1</show_legend>
+            <show_3d>0</show_3d>
+            <percent_left>0.0000</percent_left>
+            <percent_right>0.0000</percent_right>
+            <ymin_type_1>1</ymin_type_1>
+            <ymax_type_1>0</ymax_type_1>
+            <ymin_item_1>0</ymin_item_1>
+            <ymax_item_1>0</ymax_item_1>
+            <graph_items>
+                <graph_item>
+                    <sortorder>0</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>00EE00</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.degraded</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>3</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>EE0000</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.down</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>1</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>0000C8</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.incomplete</key>
+                    </item>
+                </graph_item>
+                <graph_item>
+                    <sortorder>2</sortorder>
+                    <drawtype>0</drawtype>
+                    <color>C800C8</color>
+                    <yaxisside>0</yaxisside>
+                    <calc_fnc>2</calc_fnc>
+                    <type>0</type>
+                    <item>
+                        <host>Template App Ceph Cluster</host>
+                        <key>ceph.inconsistent</key>
+                    </item>
+                </graph_item>
+            </graph_items>
+        </graph>
+    </graphs>
+</zabbix_export>
diff -rupN /root/puppet_iso/modules/zabbix/files/import/Template_App_Ceph_MON.xml /etc/puppet/modules/zabbix/files/import/Template_App_Ceph_MON.xml
--- /root/puppet_iso/modules/zabbix/files/import/Template_App_Ceph_MON.xml	1970-01-01 00:00:00.000000000 +0000
+++ /etc/puppet/modules/zabbix/files/import/Template_App_Ceph_MON.xml	2015-03-14 11:42:12.142762291 +0000
@@ -0,0 +1,83 @@
+<?xml version="1.0" encoding="UTF-8"?>
+<zabbix_export>
+    <version>2.0</version>
+    <date>2013-02-25T14:34:53Z</date>
+    <groups>
+        <group>
+            <name>Templates</name>
+        </group>
+    </groups>
+    <templates>
+        <template>
+            <template>Template App Ceph MON</template>
+            <name>Template App Ceph MON</name>
+            <groups>
+                <group>
+                    <name>Templates</name>
+                </group>
+            </groups>
+            <applications>
+                <application>
+                    <name>Ceph MON</name>
+                </application>
+            </applications>
+            <items>
+                <item>
+                    <name>Number of $1 processes</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>proc.num[ceph-mon]</key>
+                    <delay>60</delay>
+                    <history>7</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph MON</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+            </items>
+            <discovery_rules/>
+            <macros/>
+            <templates/>
+            <screens/>
+        </template>
+    </templates>
+    <triggers>
+        <trigger>
+            <expression>{Template App Ceph MON:proc.num[ceph-mon].last(0)}=0</expression>
+            <name>Ceph MON is not running on {HOSTNAME}</name>
+            <url/>
+            <status>0</status>
+            <priority>4</priority>
+            <description/>
+            <type>0</type>
+            <dependencies/>
+        </trigger>
+    </triggers>
+</zabbix_export>
diff -rupN /root/puppet_iso/modules/zabbix/files/import/Template_App_Ceph_OSD.xml /etc/puppet/modules/zabbix/files/import/Template_App_Ceph_OSD.xml
--- /root/puppet_iso/modules/zabbix/files/import/Template_App_Ceph_OSD.xml	1970-01-01 00:00:00.000000000 +0000
+++ /etc/puppet/modules/zabbix/files/import/Template_App_Ceph_OSD.xml	2015-03-14 11:44:53.282762206 +0000
@@ -0,0 +1,83 @@
+<?xml version="1.0" encoding="UTF-8"?>
+<zabbix_export>
+    <version>2.0</version>
+    <date>2013-02-25T14:34:30Z</date>
+    <groups>
+        <group>
+            <name>Templates</name>
+        </group>
+    </groups>
+    <templates>
+        <template>
+            <template>Template App Ceph OSD</template>
+            <name>Template App Ceph OSD</name>
+            <groups>
+                <group>
+                    <name>Templates</name>
+                </group>
+            </groups>
+            <applications>
+                <application>
+                    <name>Ceph OSD</name>
+                </application>
+            </applications>
+            <items>
+                <item>
+                    <name>number of $1 processes</name>
+                    <type>0</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>proc.num[ceph-osd]</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Ceph OSD</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+            </items>
+            <discovery_rules/>
+            <macros/>
+            <templates/>
+            <screens/>
+        </template>
+    </templates>
+    <triggers>
+        <trigger>
+            <expression>{Template App Ceph OSD:proc.num[ceph-osd].last(0)}=0</expression>
+            <name>Ceph OSD is down on {HOSTNAME}</name>
+            <url/>
+            <status>0</status>
+            <priority>4</priority>
+            <description/>
+            <type>0</type>
+            <dependencies/>
+        </trigger>
+    </triggers>
+</zabbix_export>
diff -rupN /root/puppet_iso/modules/zabbix/files/import/Template_Autoscale.xml /etc/puppet/modules/zabbix/files/import/Template_Autoscale.xml
--- /root/puppet_iso/modules/zabbix/files/import/Template_Autoscale.xml	1970-01-01 00:00:00.000000000 +0000
+++ /etc/puppet/modules/zabbix/files/import/Template_Autoscale.xml	2015-03-14 20:13:42.625745747 +0000
@@ -0,0 +1,138 @@
+<?xml version="1.0" encoding="UTF-8"?>
+<zabbix_export>
+    <version>2.0</version>
+    <date>2015-03-14T20:01:50Z</date>
+    <groups>
+        <group>
+            <name>Templates</name>
+        </group>
+    </groups>
+    <templates>
+        <template>
+            <template>Template Autoscale</template>
+            <name>Template Autoscale</name>
+            <groups>
+                <group>
+                    <name>Templates</name>
+                </group>
+            </groups>
+            <applications>
+                <application>
+                    <name>Cluster Usage</name>
+                </application>
+            </applications>
+            <items>
+                <item>
+                    <name>CPU Usage - Cluster Avg</name>
+                    <type>8</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>grpavg[&quot;ComputeNodes&quot;,&quot;system.cpu.load[,avg1]&quot;,last,0]</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units>%</units>
+                    <delta>0</delta>
+                    <snmpv3_contextname/>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Cluster Usage</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+                <item>
+                    <name>Rados Used Space - Cluster Avg</name>
+                    <type>8</type>
+                    <snmp_community/>
+                    <multiplier>0</multiplier>
+                    <snmp_oid/>
+                    <key>grpavg[&quot;CephNodes&quot;,&quot;ceph.rados_used&quot;,last,0]</key>
+                    <delay>30</delay>
+                    <history>90</history>
+                    <trends>365</trends>
+                    <status>0</status>
+                    <value_type>3</value_type>
+                    <allowed_hosts/>
+                    <units/>
+                    <delta>0</delta>
+                    <snmpv3_contextname/>
+                    <snmpv3_securityname/>
+                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
+                    <snmpv3_authprotocol>0</snmpv3_authprotocol>
+                    <snmpv3_authpassphrase/>
+                    <snmpv3_privprotocol>0</snmpv3_privprotocol>
+                    <snmpv3_privpassphrase/>
+                    <formula>1</formula>
+                    <delay_flex/>
+                    <params/>
+                    <ipmi_sensor/>
+                    <data_type>0</data_type>
+                    <authtype>0</authtype>
+                    <username/>
+                    <password/>
+                    <publickey/>
+                    <privatekey/>
+                    <port/>
+                    <description/>
+                    <inventory_link>0</inventory_link>
+                    <applications>
+                        <application>
+                            <name>Cluster Usage</name>
+                        </application>
+                    </applications>
+                    <valuemap/>
+                </item>
+            </items>
+            <discovery_rules/>
+            <macros/>
+            <templates/>
+            <screens/>
+        </template>
+    </templates>
+    <triggers>
+        <trigger>
+            <expression>{Template Autoscale:grpavg[&quot;ComputeNodes&quot;,&quot;system.cpu.load[,avg1]&quot;,last,0].last()}&gt;80</expression>
+            <name>High CPU utilization on a Compute Cluster</name>
+            <url/>
+            <status>0</status>
+            <priority>2</priority>
+            <description>Triggers when cpu load average aggregated from all compute nodes goes above configured value.</description>
+            <type>0</type>
+            <dependencies/>
+        </trigger>
+        <trigger>
+            <expression>{Template Autoscale:grpavg[&quot;CephNodes&quot;,&quot;ceph.rados_used&quot;,last,0].last()}&lt;119944467435</expression>
+            <name>Low Ceph Cluster Disk Space</name>
+            <url/>
+            <status>0</status>
+            <priority>2</priority>
+            <description>Triggers when a free disk space on entire ceph cluster (rados df) drops down below configured value.</description>
+            <type>0</type>
+            <dependencies/>
+        </trigger>
+    </triggers>
+</zabbix_export>
diff -rupN /root/puppet_iso/modules/zabbix/files/scripts/ceph-status.sh /etc/puppet/modules/zabbix/files/scripts/ceph-status.sh
--- /root/puppet_iso/modules/zabbix/files/scripts/ceph-status.sh	1970-01-01 00:00:00.000000000 +0000
+++ /etc/puppet/modules/zabbix/files/scripts/ceph-status.sh	2015-03-14 13:13:02.896759355 +0000
@@ -0,0 +1,300 @@
+#!/bin/bash
+
+ceph_bin="sudo /usr/bin/ceph"
+rados_bin="sudo /usr/bin/rados"
+
+# Initialising variables
+# See: http://ceph.com/docs/master/rados/operations/pg-states/
+creating=0
+active=0
+clean=0
+down=0
+replay=0
+splitting=0
+scrubbing=0
+degraded=0
+inconsistent=0
+peering=0
+repair=0
+recovering=0
+backfill=0
+waitBackfill=0
+incomplete=0
+stale=0
+remapped=0
+
+# Get data
+pginfo=$(echo -n "  pgmap $($ceph_bin pg stat)" | sed -n "s/.*pgmap/pgmap/p")
+pgtotal=$(echo $pginfo | cut -d':' -f2 | sed 's/[^0-9]//g')
+pgstats=$(echo $pginfo | cut -d':' -f3 | cut -d';' -f1| sed 's/ /\\ /g')
+pggdegraded=$(echo $pginfo | sed -n '/degraded/s/.* degraded (\([^%]*\)%.*/\1/p')
+if [[ "$pggdegraded" == "" ]]
+then
+  pggdegraded=0
+fi
+# unfound (0.004%)
+pgunfound=$(echo $pginfo | cut -d';' -f2|sed -n '/unfound/s/.*unfound (\([^%]*\)%.*/\1/p')
+if [[ "$pgunfound" == "" ]]
+then
+  pgunfound=0
+fi
+
+# write kbps B/s
+rdbps=$(echo $pginfo | sed -n '/pgmap/s/.* \([0-9]* .\)B\/s rd.*/\1/p' | sed -e "s/K/*1000/ig;s/M/*1000*1000/i;s/G/*1000*1000*1000/i;s/E/*1000*1000*1000*1000/i" | bc)
+if [[ "$rdbps" == "" ]]
+then
+  rdbps=0
+fi
+
+# write kbps B/s
+wrbps=$(echo $pginfo | sed -n '/pgmap/s/.* \([0-9]* .\)B\/s wr.*/\1/p' | sed -e "s/K/*1000/ig;s/M/*1000*1000/i;s/G/*1000*1000*1000/i;s/E/*1000*1000*1000*1000/i" | bc)
+if [[ "$wrbps" == "" ]]
+then
+  wrbps=0
+fi
+
+# ops
+ops=$(echo $pginfo | sed -n '/pgmap/s/.* \([0-9]*\) op\/s.*/\1/p')
+if [[ "$ops" == "" ]]
+then
+  ops=0
+fi
+
+# Explode array
+IFS=', ' read -a array <<< "$pgstats"
+for element in "${array[@]}"
+do
+    element=$(echo "$element" | sed 's/^ *//g')
+    # Get elements
+    number=$(echo $element | cut -d' ' -f1)
+    data=$(echo $element | cut -d' ' -f2)
+
+    # Agregate data
+    if [ "$(echo $data | grep creating | wc -l)" == 1 ]
+    then
+	  creating=$(echo $creating+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep active | wc -l)" == 1 ]
+    then
+	  active=$(echo $active+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep clean | wc -l)" == 1 ]
+    then
+	  clean=$(echo $clean+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep down | wc -l)" == 1 ]
+    then
+	  down=$(echo $down+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep replay | wc -l)" == 1 ]
+    then
+	  replay=$(echo $replay+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep splitting | wc -l)" == 1 ]
+    then
+	  splitting=$(echo $splitting+$number|bc)	  
+    fi
+
+    if [ "$(echo $data | grep scrubbing | wc -l)" == 1 ]
+    then
+	  scrubbing=$(echo $scrubbing+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep degraded | wc -l)" == 1 ]
+    then
+	  degraded=$(echo $degraded+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep inconsistent | wc -l)" == 1 ]
+    then
+	  inconsistent=$(echo $inconsistent+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep peering | wc -l)" == 1 ]
+    then
+	  peering=$(echo $peering+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep repair | wc -l)" == 1 ]
+    then
+	  repair=$(echo $repair+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep recovering | wc -l)" == 1 ]
+    then
+	  recovering=$(echo $recovering+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep backfill | wc -l)" == 1 ]
+    then
+	  backfill=$(echo $backfill+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep "wait-backfill" | wc -l)" == 1 ]
+    then
+	  waitBackfill=$(echo $waitBackfill+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep incomplete | wc -l)" == 1 ]
+    then
+	  incomplete=$(echo $incomplete+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep stale | wc -l)" == 1 ]
+    then
+	  stale=$(echo $stale+$number|bc)
+    fi
+
+    if [ "$(echo $data | grep remapped | wc -l)" == 1 ]
+    then
+	  remapped=$(echo $remapped+$number|bc)
+    fi
+done
+
+function ceph_osd_up_percent()
+{
+  OSD_COUNT=$($ceph_bin osd dump |grep "^osd"| wc -l)
+  OSD_DOWN=$($ceph_bin osd dump |grep "^osd"| awk '{print $1 " " $2 " " $3}'|grep up|wc -l)
+  COUNT=$(echo "scale=2; $OSD_DOWN*100/$OSD_COUNT" |bc)
+  if [[ "$COUNT" != "" ]]
+  then
+    echo $COUNT
+  else
+    echo "0"
+  fi
+}
+
+function ceph_osd_in_percent()
+{
+  OSD_COUNT=$($ceph_bin osd dump |grep "^osd"| wc -l)
+  OSD_DOWN=$($ceph_bin osd dump |grep "^osd"| awk '{print $1 " " $2 " " $3}'|grep in|wc -l)
+  COUNT=$(echo "scale=2; $OSD_DOWN*100/$OSD_COUNT" | bc)
+  if [[ "$COUNT" != "" ]]
+  then
+    echo $COUNT
+  else
+    echo "0"
+  fi
+
+}
+
+function ceph_mon_get_active()
+{
+  ACTIVE=$($ceph_bin status|sed -n '/monmap/s/.* \([0-9]*\) mons.*/\1/p')
+  if [[ "$ACTIVE" != "" ]]
+  then
+    echo $ACTIVE
+  else
+    echo 0
+  fi
+}
+
+# Return the value
+case $1 in
+  health)
+    status=$($ceph_bin health | awk '{print $1}')
+    case $status in
+      HEALTH_OK)
+        echo 1
+      ;;
+      HEALTH_WARN)
+        echo 2
+      ;;
+      HEALTH_ERR)
+        echo 3
+      ;;
+      *)
+        echo -1
+      ;;
+    esac
+  ;;
+  rados_total)
+    $rados_bin df | grep "total space"| awk '{print $3}'
+  ;;
+  rados_used)
+    $rados_bin df | grep "total used"| awk '{print $3}'
+  ;;
+  rados_free)
+    $rados_bin df | grep "total avail"| awk '{print $3}'
+  ;;
+  mon)
+    ceph_mon_get_active
+  ;;
+  up)
+    ceph_osd_up_percent
+  ;;
+  "in")
+    ceph_osd_in_percent
+  ;;
+  degraded_percent)
+    echo $pggdegraded
+  ;;
+  pgtotal)
+    echo $pgtotal
+  ;;
+  creating)
+    echo $creating
+  ;;
+  active)
+    echo $active
+  ;;
+  clean)
+    echo $clean
+  ;;
+  down)
+    echo $down
+  ;;
+  replay)
+    echo $replay
+  ;;
+  splitting)
+    echo $splitting
+  ;;
+  scrubbing)
+    echo $scrubbing
+  ;;
+  degraded)
+    echo $degraded
+  ;;
+  inconsistent)
+    echo $inconsistent
+  ;;
+  peering)
+    echo $peering
+  ;;
+  repair)
+    echo $repair
+  ;;
+  recovering)
+    echo $recovering
+  ;;
+  backfill)
+    echo $backfill
+  ;;
+  waitBackfill)
+    echo $waitBackfill
+  ;;
+  incomplete)
+    echo $incomplete
+  ;;
+  stale)
+    echo $stale
+  ;;
+  remapped)
+    echo $remapped
+  ;;
+  ops)
+    echo $ops
+  ;;
+  wrbps)
+    echo $wrbps
+  ;;
+  rdbps)
+    echo $rdbps
+  ;;
+esac
diff -rupN /root/puppet_iso/modules/zabbix/files/zabbix-sudo /etc/puppet/modules/zabbix/files/zabbix-sudo
--- /root/puppet_iso/modules/zabbix/files/zabbix-sudo	2015-03-12 16:12:33.000000000 +0000
+++ /etc/puppet/modules/zabbix/files/zabbix-sudo	2015-03-14 13:14:11.383759315 +0000
@@ -4,3 +4,6 @@ zabbix ALL = NOPASSWD: /usr/bin/mysqladm
 zabbix ALL = NOPASSWD: /usr/bin/socat
 zabbix ALL = NOPASSWD: /usr/sbin/iptstate
 zabbix ALL = NOPASSWD: /usr/sbin/crm_resource
+zabbix ALL = NOPASSWD: /usr/bin/ceph pg stat
+zabbix ALL = NOPASSWD: /usr/bin/ceph osd dump
+zabbix ALL = NOPASSWD: /usr/bin/rados df
diff -rupN /root/puppet_iso/modules/zabbix/manifests/monitoring/ceph_mon.pp /etc/puppet/modules/zabbix/manifests/monitoring/ceph_mon.pp
--- /root/puppet_iso/modules/zabbix/manifests/monitoring/ceph_mon.pp	1970-01-01 00:00:00.000000000 +0000
+++ /etc/puppet/modules/zabbix/manifests/monitoring/ceph_mon.pp	2015-03-14 13:15:26.726759291 +0000
@@ -0,0 +1,92 @@
+class zabbix::monitoring::ceph_mon {
+
+  include zabbix::params
+
+  # Ceph (MON)
+  if defined(Class['ceph::mon']) {
+
+    zabbix_template_link { "$zabbix::params::host_name Template App Ceph Cluster":
+      host => $zabbix::params::host_name,
+      template => 'Template App Ceph Cluster',
+      api => $zabbix::params::api_hash,
+    }
+
+    zabbix_template_link { "$zabbix::params::host_name Template App Ceph MON":
+      host => $zabbix::params::host_name,
+      template => 'Template App Ceph MON',
+      api => $zabbix::params::api_hash,
+    }
+
+    zabbix::agent::userparameter {
+      'ceph.health':
+        command => '/etc/zabbix/scripts/ceph-status.sh health';
+      'ceph.osd_in':
+        command => '/etc/zabbix/scripts/ceph-status.sh in';
+      'ceph.osd_up':
+        command => '/etc/zabbix/scripts/ceph-status.sh up';
+      'ceph.active':
+        command => '/etc/zabbix/scripts/ceph-status.sh active';
+      'ceph.backfill':
+        command => '/etc/zabbix/scripts/ceph-status.sh backfill';
+      'ceph.clean':
+        command => '/etc/zabbix/scripts/ceph-status.sh clean';
+      'ceph.creating':
+        command => '/etc/zabbix/scripts/ceph-status.sh creating';
+      'ceph.degraded':
+        command => '/etc/zabbix/scripts/ceph-status.sh degraded';
+      'ceph.degraded_percent':
+        command => '/etc/zabbix/scripts/ceph-status.sh degraded_percent';
+      'ceph.down':
+        command => '/etc/zabbix/scripts/ceph-status.sh down';
+      'ceph.incomplete':
+        command => '/etc/zabbix/scripts/ceph-status.sh incomplete';
+      'ceph.inconsistent':
+        command => '/etc/zabbix/scripts/ceph-status.sh inconsistent';
+      'ceph.peering':
+        command => '/etc/zabbix/scripts/ceph-status.sh peering';
+      'ceph.recovering':
+        command => '/etc/zabbix/scripts/ceph-status.sh recovering';
+      'ceph.remapped':
+        command => '/etc/zabbix/scripts/ceph-status.sh remapped';
+      'ceph.repair':
+        command => '/etc/zabbix/scripts/ceph-status.sh repair';
+      'ceph.replay':
+        command => '/etc/zabbix/scripts/ceph-status.sh replay';
+      'ceph.scrubbing':
+        command => '/etc/zabbix/scripts/ceph-status.sh scrubbing';
+      'ceph.splitting':
+        command => '/etc/zabbix/scripts/ceph-status.sh splitting';
+      'ceph.stale':
+        command => '/etc/zabbix/scripts/ceph-status.sh stale';
+      'ceph.pgtotal':
+        command => '/etc/zabbix/scripts/ceph-status.sh pgtotal';
+      'ceph.waitBackfill':
+        command => '/etc/zabbix/scripts/ceph-status.sh waitBackfill';
+      'ceph.mon':
+        command => '/etc/zabbix/scripts/ceph-status.sh mon';
+      'ceph.rados_total':
+        command => '/etc/zabbix/scripts/ceph-status.sh rados_total';
+      'ceph.rados_used':
+        command => '/etc/zabbix/scripts/ceph-status.sh rados_used';
+      'ceph.rados_free':
+        command => '/etc/zabbix/scripts/ceph-status.sh rados_free';
+      'ceph.wrbps':
+        command => '/etc/zabbix/scripts/ceph-status.sh wrbps';
+      'ceph.rdbps':
+        command => '/etc/zabbix/scripts/ceph-status.sh rdbps';
+      'ceph.ops':
+        command => '/etc/zabbix/scripts/ceph-status.sh ops';
+    }
+
+  }
+
+  # Ceph (OSD)
+  if defined(Class['ceph::osd']) {
+
+    zabbix_template_link { "$zabbix::params::host_name Template App Ceph OSD":
+      host => $zabbix::params::host_name,
+      template => 'Template App Ceph OSD',
+      api => $zabbix::params::api_hash,
+    }
+  }
+}
diff -rupN /root/puppet_iso/modules/zabbix/manifests/monitoring.pp /etc/puppet/modules/zabbix/manifests/monitoring.pp
--- /root/puppet_iso/modules/zabbix/manifests/monitoring.pp	2015-03-12 16:12:33.000000000 +0000
+++ /etc/puppet/modules/zabbix/manifests/monitoring.pp	2015-03-14 12:07:57.168761450 +0000
@@ -82,4 +82,5 @@ class zabbix::monitoring {
   include zabbix::monitoring::openvswitch_mon
   include zabbix::monitoring::ceilometer_mon
   include zabbix::monitoring::ceilometer_compute_mon
+  include zabbix::monitoring::ceph_mon
 }
diff -rupN /root/puppet_iso/modules/zabbix/manifests/server/config.pp /etc/puppet/modules/zabbix/manifests/server/config.pp
--- /root/puppet_iso/modules/zabbix/manifests/server/config.pp	2015-03-12 16:12:33.000000000 +0000
+++ /etc/puppet/modules/zabbix/manifests/server/config.pp	2015-03-14 20:04:57.875746025 +0000
@@ -2,7 +2,7 @@ class zabbix::server::config {
 
   include zabbix::params
 
-  zabbix_hostgroup { $zabbix::params::host_groups:
+  zabbix_hostgroup { $zabbix::params::host_groups_all:
     ensure => present,
     api    => $zabbix::params::api_hash,
   }
@@ -270,4 +270,26 @@ class zabbix::server::config {
     xml_file => '/etc/zabbix/import/Template_App_OpenStack_Ceilometer_Compute.xml',
     api => $zabbix::params::api_hash,
   }
+  # Ceph
+  zabbix_configuration_import { 'Template_App_Ceph_Cluster.xml Import':
+    ensure   => present,
+    xml_file => '/etc/zabbix/import/Template_App_Ceph_Cluster.xml',
+    api => $zabbix::params::api_hash,
+  }
+  zabbix_configuration_import { 'Template_App_Ceph_MON.xml Import':
+    ensure   => present,
+    xml_file => '/etc/zabbix/import/Template_App_Ceph_MON.xml',
+    api => $zabbix::params::api_hash,
+  }
+  zabbix_configuration_import { 'Template_App_Ceph_OSD.xml Import':
+    ensure   => present,
+    xml_file => '/etc/zabbix/import/Template_App_Ceph_OSD.xml',
+    api => $zabbix::params::api_hash,
+  }
+  # Autoscale
+  zabbix_configuration_import { 'Template_Autoscale.xml Import':
+    ensure   => present,
+    xml_file => '/etc/zabbix/import/Template_Autoscale.xml',
+    api => $zabbix::params::api_hash,
+  }
 }
