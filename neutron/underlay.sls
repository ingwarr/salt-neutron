{%- from "neutron/map.jinja" import underlay with context %}
{%- if underlay.enabled %}

neutron_server_packages:
  pkg.installed:
  - names: {{ underlay.pkgs }}


/etc/neutron/neutron.conf:
  file.managed:
  - source: salt://neutron/files/underlay/neutron.conf.j2
  - template: jinja
  - require:
    - pkg: neutron_server_packages


/etc/neutron/dnsmasq.conf:
  file.managed:
  - source: salt://neutron/files/underlay/dnsmasq.conf.j2
  - template: jinja
  - require:
    - pkg: neutron_server_packages

neutron_plugins_clear:
  cmd.run:
  - name: rm -rf /etc/neutron/plugins/ml2/*
  - require:
    - pkg: neutron_server_packages

/lib/systemd/system/neutron-linuxbridge-agent.service:
  file.managed:
  - source: salt://neutron/files/underlay/neutron-linuxbridge-agent.service
  - require:
    - pkg: neutron_server_packages

neutron_db_manage:
  cmd.run:
  - name: neutron-db-manage --config-file /etc/neutron/neutron.conf  upgrade head
  - require:
    - file: /etc/neutron/neutron.conf
    - cmd: neutron_plugins_clear
    
neutron_server_services:
  service.running:
  - names: {{ underlay.services }}
  - enable: true
  - watch:
    - file: /etc/neutron/neutron.conf
    - file: /etc/neutron/dnsmasq.conf
    - cmd: neutron_db_manage
    - file: /lib/systemd/system/neutron-linuxbridge-agent.service


{%- endif %}
