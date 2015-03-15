class zabbix::monitoring::ceph_mon {

  include zabbix::params

  # Ceph (MON)
  if defined(Class['ceph::mon']) {

    zabbix_template_link { "$zabbix::params::host_name Template App Ceph Cluster":
      host => $zabbix::params::host_name,
      template => 'Template App Ceph Cluster',
      api => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::host_name Template App Ceph MON":
      host => $zabbix::params::host_name,
      template => 'Template App Ceph MON',
      api => $zabbix::params::api_hash,
    }

    zabbix::agent::userparameter {
      'ceph.health':
        command => '/etc/zabbix/scripts/ceph-status.sh health';
      'ceph.osd_in':
        command => '/etc/zabbix/scripts/ceph-status.sh in';
      'ceph.osd_up':
        command => '/etc/zabbix/scripts/ceph-status.sh up';
      'ceph.active':
        command => '/etc/zabbix/scripts/ceph-status.sh active';
      'ceph.backfill':
        command => '/etc/zabbix/scripts/ceph-status.sh backfill';
      'ceph.clean':
        command => '/etc/zabbix/scripts/ceph-status.sh clean';
      'ceph.creating':
        command => '/etc/zabbix/scripts/ceph-status.sh creating';
      'ceph.degraded':
        command => '/etc/zabbix/scripts/ceph-status.sh degraded';
      'ceph.degraded_percent':
        command => '/etc/zabbix/scripts/ceph-status.sh degraded_percent';
      'ceph.down':
        command => '/etc/zabbix/scripts/ceph-status.sh down';
      'ceph.incomplete':
        command => '/etc/zabbix/scripts/ceph-status.sh incomplete';
      'ceph.inconsistent':
        command => '/etc/zabbix/scripts/ceph-status.sh inconsistent';
      'ceph.peering':
        command => '/etc/zabbix/scripts/ceph-status.sh peering';
      'ceph.recovering':
        command => '/etc/zabbix/scripts/ceph-status.sh recovering';
      'ceph.remapped':
        command => '/etc/zabbix/scripts/ceph-status.sh remapped';
      'ceph.repair':
        command => '/etc/zabbix/scripts/ceph-status.sh repair';
      'ceph.replay':
        command => '/etc/zabbix/scripts/ceph-status.sh replay';
      'ceph.scrubbing':
        command => '/etc/zabbix/scripts/ceph-status.sh scrubbing';
      'ceph.splitting':
        command => '/etc/zabbix/scripts/ceph-status.sh splitting';
      'ceph.stale':
        command => '/etc/zabbix/scripts/ceph-status.sh stale';
      'ceph.pgtotal':
        command => '/etc/zabbix/scripts/ceph-status.sh pgtotal';
      'ceph.waitBackfill':
        command => '/etc/zabbix/scripts/ceph-status.sh waitBackfill';
      'ceph.mon':
        command => '/etc/zabbix/scripts/ceph-status.sh mon';
      'ceph.rados_total':
        command => '/etc/zabbix/scripts/ceph-status.sh rados_total';
      'ceph.rados_used':
        command => '/etc/zabbix/scripts/ceph-status.sh rados_used';
      'ceph.rados_free':
        command => '/etc/zabbix/scripts/ceph-status.sh rados_free';
      'ceph.wrbps':
        command => '/etc/zabbix/scripts/ceph-status.sh wrbps';
      'ceph.rdbps':
        command => '/etc/zabbix/scripts/ceph-status.sh rdbps';
      'ceph.ops':
        command => '/etc/zabbix/scripts/ceph-status.sh ops';
    }

  }

  # Ceph (OSD)
  if defined(Class['ceph::osd']) {

    zabbix_template_link { "$zabbix::params::host_name Template App Ceph OSD":
      host => $zabbix::params::host_name,
      template => 'Template App Ceph OSD',
      api => $zabbix::params::api_hash,
    }
  }
}
