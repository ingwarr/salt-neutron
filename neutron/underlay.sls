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
  - name: rm -rf /etc/neutron/plugins/ml2/* && touch /etc/neutron/plugins/ml2/ml2_conf.ini
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

neutron_bridge_creation:
  cmd.run:
  - name: brctl addbr {{ underlay.bridge_name }} && brctl addif {{ underlay.bridge_name }} {{ underlay.provision_interface }} && ip addr add {{ underlay.provision_address }}/{{ underlay.provision_netmask }} dev {{ underlay.bridge_name }} && ip link set {{ underlay.provision_interface }} up
  - require:
    - pkg: neutron_server_packages

/etc/sudoers.d/neutron_sudoers:
  file.managed:
  - source: salt://neutron/files/underlay/neutron_sudoers
  - require:
    - pkg: neutron_server_packages

neutron_server_services:
  service.running:
  - names: {{ underlay.services }}
  - enable: true
  - reload: true
  - watch:
    - file: /etc/neutron/neutron.conf
    - file: /etc/neutron/dnsmasq.conf
    - file: /lib/systemd/system/neutron-linuxbridge-agent.service
    - file: /etc/sudoers.d/neutron_sudoers
    - cmd: neutron_db_manage
    - cmd: neutron_bridge_creation

{%- endif %}
