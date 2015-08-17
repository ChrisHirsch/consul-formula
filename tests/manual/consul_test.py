set server_target '*'

verify that /etc/consul.conf contains
"data_dir": "/opt/consul/data",
"server": true
AND
/etc/salt/grains contains
consul_server_target_from_pillar: true

set server_target 'noboxmatch'
verify that /etc/consul.conf contains
"data_dir": "/opt/consul/data",
"server": false
AND
/etc/salt/grains DOES NOT contain
consul_server_target_from_pillar: true

set server_target 'noboxmatch' 
AND
salt 'boxmatch' grains.setval consul_server_target True
verify that /etc/consul.conf contains
"data_dir": "/opt/consul/data",
"server": true
AND
/etc/salt/grains contains
consul_server_target_from_pillar: true


set server_target 'noboxmatch' 
AND
salt 'boxmatch' grains.delval consul_server_target destructive=True
verify that /etc/consul.conf contains
"data_dir": "/opt/consul/data",
"server": false
AND
/etc/salt/grains DOES NOT contain
consul_server_target_from_pillar: true






