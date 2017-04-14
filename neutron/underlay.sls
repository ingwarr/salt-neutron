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

neutron_server_services:
  service.running:
  - names: {{ underlay.services }}
  - enable: true
  - watch:
    - file: /etc/neutron/neutron.conf
    - file: /etc/neutron/dnsmasq.conf

{%- endif %}
