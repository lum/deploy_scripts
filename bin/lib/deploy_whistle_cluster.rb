#!/usr/bin/env ruby

$threads[:db001] = Thread.new { deploy_server "db001", "BigCouch Server 1", ["winkstart_deploy_bigcouch", "chef-client::first_start"], {:flavor => 2 } }
sleep 20
$threads[:db002] = Thread.new { deploy_server "db002", "BigCouch Server 2", ["winkstart_deploy_bigcouch", "chef-client::first_start"], {:flavor => 2 } }
sleep 20
$threads[:db003] = Thread.new { deploy_server "db003", "BigCouch Server 3", ["winkstart_deploy_bigcouch", "chef-client::first_start"], {:flavor => 2 } }
sleep 20
$threads[:apps001] = Thread.new { deploy_server "apps001", "App Server 1", ["winkstart_deploy_haproxy", "winkstart_deploy_opensips", "winkstart_deploy_whapps"], {:flavor => 2} }
sleep 20
$threads[:apps002] = Thread.new { deploy_server "apps002", "App Server 2", ["winkstart_deploy_haproxy", "winkstart_deploy_opensips", "winkstart_deploy_whapps"], {:flavor => 2} }
sleep 20
$threads[:fs001] = Thread.new { deploy_server "fs001", "FreeSWITCH Server 1", ["winkstart_deploy_whistle_fs", "chef-client::first_start"], {:flavor => 2} }
sleep 20
$threads[:fs002] = Thread.new { deploy_server "fs002", "FreeSWITCH Server 2", ["winkstart_deploy_whistle_fs", "chef-client::first_start"], {:flavor => 2} }
sleep 20
$threads[:db001].join(3600)
$threads[:db002].join(3600)
$threads[:db003].join(3600)
$threads[:apps001].join(3600)
$threads[:apps002].join(3600)
$threads[:fs001].join(3600)
$threads[:fs002].join(3600)
