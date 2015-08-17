{%- set install_path = salt['pillar.get']('consul:install_path', '/usr/local/bin') %}
{%- set ui_install_path = salt['pillar.get']('consul:ui_install_path', '/opt/consul/ui') %}
{%- set version = salt['pillar.get']('consul:version', '0.5.2') %}
{%- set user = salt['pillar.get']('consul:user', 'consul') %}
{%- set group = salt['pillar.get']('consul:group', 'consul') %}
{%- set home_dir = salt['pillar.get']('consul:home', '/opt/consul') %}
{%- set domain = salt['pillar.get']('consul:domain', 'consul.') %}
{%- set manage_firewall = salt['pillar.get']('consul:manage_firewall', False) %}

{%- set source_url = 'https://dl.bintray.com/mitchellh/consul/' ~ version ~ '_linux_amd64.zip' %}
{%- set source_hash =  salt['pillar.get']('consul:source_hash', 'md5=37000419d608fd34f0f2d97806cf7399') %}

{%- set ui_source_url = 'https://dl.bintray.com/mitchellh/consul/' ~ version ~ '_web_ui.zip' %}
{%- set ui_source_hash = salt['pillar.get']('consul:ui_source_hash', 'md5=eb98ba602bc7e177333eb2e520881f4f') %}

{%- set targeting_method = salt['pillar.get']('consul:targeting_method', 'glob') %}

# If the user has explicitly set the consul_server_target to True then we know that 
# the node should be a consul server and we explicity set the grain for consul_server_target grain to True
# so we can then send the grain up to the salt mine and gather all nodes who are a consul server
{%- if salt['grains.get']('consul_server_target') == True: %}
       {%- set server_target = salt['grains.get']('consul_server_target') %}
       {%- set is_server = True %}
# Since we don't have an explicit grain set (consul_server_target) then look for the pillar consul:server_target
# If our host matches that server_target then set the consul_server_target_from_pillar grain to True otherwise
# remove consul_server_target_from_pillar grain 
{%- else %}
       {%- set server_target = salt['pillar.get']('consul:server_target') %}
       {%- set is_server = salt['match.' ~ targeting_method](server_target) %}
       # If the node is a server then set the consul_server_target_from_pillar grain on the node to True
       {%- if is_server == True %}
          {%- set grain = salt['grains.setval']('consul_server_target_from_pillar', True) %}
       # The node is NOT a  server so remove the grain consul_server_target_from_pillar grain on the node completely 
       {%- else %}
          # Use delval vs remove otherwise the key and value won't actually be removed
          {%- set grain = salt['grains.delval']('consul_server_target_from_pillar', destructive=True) %}
       {%- endif %}
       # Update the mind with our newly set/deleted grains
{%- endif %}
# We probably don't want to send this every time..maybe only for the two grains we care about?
{%- set force_mine_update = salt['mine.send']('grains.items') %}

{%- if salt['grains.get']('consul_ui_target') != '': %}
       {%- set ui_target = salt['grains.get']('consul_ui_target') %}
       {%- set is_ui = True %}
{%- else %}
       {%- set ui_target = salt['pillar.get']('consul:ui_target') %}
       {%- set is_ui = salt['match.' ~	targeting_method](ui_target) %}
{%- endif %}

{%- set ui_public_target = salt['pillar.get']('consul:ui_public_target') %}
{%- set bootstrap_target = salt['pillar.get']('consul:bootstrap_target') %}

{%- set ui_public_target = salt['match.' ~ targeting_method](ui_public_target) %}

{%- if salt['grains.get']('datacenter') != '': %}
       {%- set datacenter = salt['grains.get']('datacenter') %}
{%- else %}
       {%- set datacenter = salt['pillar.get']('consul:datacenter') %}

{%- endif %}

{%- set nodename = salt['grains.get']('nodename') %}
{%- set join_server = [] %}
# Create a list of servers that can be used to join the cluster
# Jinja vars are immutable in a loop so you have to do the 'do' trick to append to the list
# http://stackoverflow.com/questions/17925674/jinja2-local-global-variable
# Loop through all boxes that are tagged as a consul_server_target (True) or consul_server_target_from_pillar (True) 
# and get the hostname of each box and then append that hostname to a list of all our consul servers
# @LOOKHERE - Is there a way to combine the two for loops like ('consul_server_target:True or consul_server_target_from_pillar:True')?
# Otherwise we do a lot LOT of redundant server calls
{% set servers = [] %}
{% for host, servers in salt['mine.get']('consul_server_target:True', 'network.get_hostname', expr_form='grain').items() %}
    {% do join_server.append(servers) %}
{%- endfor %}
{% for host, servers in salt['mine.get']('consul_server_target_from_pillar:True', 'network.get_hostname', expr_form='grain').items() %}
    {% do join_server.append(servers) %}
{%- endfor %}

{%- set consul = {} %}
{%- do consul.update({

    'install_path': install_path,
    'ui_install_path': ui_install_path,
    'version': version,
    'source_url': source_url,
    'source_hash': source_hash,
    'ui_source_url': ui_source_url,
    'ui_source_hash': ui_source_hash,
    'user': user,
    'group': group,
    'home_dir': home_dir,
    'config_dir': '/etc/consul.d',
    'config_file': '/etc/consul.conf',
    'log_file': '/var/log/consul.log',
    'is_server': is_server,
    'is_ui': is_ui,
    'ui_public_target': ui_public_target,
    'domain': domain,
    'bootstrap_target': bootstrap_target,
    'join_server': join_server,
    'datacenter': datacenter,
    'manage_firewall': manage_firewall,
    'servers': servers
}) %}
