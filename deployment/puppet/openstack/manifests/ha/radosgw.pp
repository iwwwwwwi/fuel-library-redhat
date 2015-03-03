# HA configuration for Ceph RADOS Gateway
class openstack::ha::radosgw (
  $servers,
) {

  openstack::ha::haproxy_service { 'radosgw':
    order               => '130',
    listen_port         => 8080,
    balancermember_port => 6780,
    server_names        => filter_hash($servers, 'name'),
    ipaddresses         => filter_hash($servers, 'storage_address'),
    public              => true,

    haproxy_config_options => {
      'option'         => ['httplog', 'httpchk GET /'],
    },
  }
}
