#!/usr/bin/env ruby
#
#

require 'pathname'
$topdir = File.join(File.dirname(Pathname.new(__FILE__).realpath))

require 'rubygems'
require 'systemu'
require 'optparse'
require 'logger'

$svrlog = Logger.new("/tmp/server-provisioning.log")
$svrlog.level = Logger::INFO

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

$threads = {}
$config = "~/.chef/knife.rb"

$log.debug "Deploying with config: #{$config}"
time_started = Time.new

# Shamelessly yanked and modified from Ruby on Rails
# https://github.com/rails/rails
class Numeric
  # Enables the use of time calculations and declarations, like 45.minutes + 2.hours + 4.years.
  def seconds
    self
  end
  alias :second :seconds

  def minutes
    self * 60
  end
  alias :minute :minutes

  def hours
    self * 3600
  end
  alias :hour :hours

  def days
    self * 24.hours
  end
  alias :day :days

  def weeks
    self * 7.days
  end
  alias :week :weeks

  def fortnights
    self * 2.weeks
  end
  alias :fortnight :fortnights
end

class CommandTimeout < Exception
end

class RackspaceException < Exception
end

#def run_command command, reverse, filename = nil
def run_command command, filename = nil
  status, stdout, stderr = ""
  begin
	status, stdout, stderr = systemu command
	raise RackspaceException if status.to_i == 256
  rescue CommandTimeout
  	$log.error "Server took too long to deploy.  Please manually deploy:"
  	$log.error command
	$log.error "=++==++= STDERR"
  	$log.error stderr
	$log.error "=++==++= STDOUT"
  	$log.error stdout
  rescue RackspaceException
  	if stdout.include?("Name or service not known")
	 $log.error "Rackspace Server Creation Failure.  Retrying command in 2 minutes:"
	  $svrlog.error "Rackspace Server Creation Failure.  Retrying command in 2 minutes:"
	else
	  $log.error "General Server Creation Failure.  Retrying command in 2 minutes:"
	  $svrlog.error "General Server Creation Failure.  Retrying command in 2 minutes:"
	end
  	$log.error command
	$log.error "=++==++= STDERR"
  	$log.error stderr
	$log.error "=++==++= STDOUT"
  	$log.error stdout
  	sleep 2.minutes
  	retry
  end

  if filename
  	$log.debug "Logging system output to /tmp/#{filename}.log"
  	File.open("/tmp/#{filename}.log", 'w') do |file|
  	  file.write "COMMAND =====================\r\n"
  	  file.write "#{command}\r\n"
  	  file.write "STATUS: #{status} ===================\r\n"
  	  file.write "STDERR ======================\r\n"
  	  file.write(stderr)
  	  file.write "STDOUT ======================\r\n"
  	  file.write(stdout)
	end
  else
  	if status.to_i > 0
	  $log.debug "=++==++= STDOUT"
	  $log.debug stdout
	  $log.info "=++==++= STDERR"
	  $log.info stderr
	end
  end
end

def timestamp id, message
  puts "#{id} #{message} #{Time.now.to_i}"
end

def deploy_server node, node_string, ip, roles, recipes, p = {}
  # Set up the defaults
  gems = "centos6-rvm"
  image = 127
  flavor = 2

  # Set up the command
  node_name = "#{node}"
  $log.info "#{node} deploying"
  command = "knife rackspace server create"
  command += " -E 'staging'"
  #command += " -r 'role[e5f1f5a6d9c8899982c3ccc7fcd4dd6e]'"
  command += " -r 'role[base_centos]'"
  roles.each do |role|
  	command += ",'role[#{role}]'"
  end
  recipes.each do |recipe|
    command += ",'recipe[#{recipe}]'"
  end
  command += " -I #{image}"
  command += " -f #{flavor}"
  command += " -N #{node}"
  command += " -S #{node}.2600hz.com"
  command += " -d #{gems}"
  command += " -c #{$config}"
  # Open a server provisioning file handle for logging
  $svrlog.info(command)
  puts command
  run_command command, node
  $log.info "#{node} deployed"
end

def refresh_servers roles
  ts = Time.now.to_i
  $log.info "rs-#{roles.join(',')} start (#{ts})"
  search = "role:#{$env} AND role:#{$d_id}"
  roles.each do |role|
  	search += " AND role:#{role}"
  end
  command = "knife ssh '#{search}' chef-client -a ipaddress"
  run_command command, "rs-#{roles.join(',')}-#{ts}"
  $log.info "rs-#{roles.join(',')} done (#{ts})"
end

$threads[:db001] = Thread.new { deploy_server "db001-staging-dfw", "BigCouch Node 1", "208.90.213.57", [ "staging", "rvm", "dfw", "dynect", "bigcouch" ], [ "iptables", "bigcouch::cluster_internal", "hosts", "rsyslog::client" ] }
sleep 5

$threads[:db002] = Thread.new { deploy_server "db002-staging-dfw", "BigCouch Node 2", "208.90.213.58", [ "staging", "rvm", "dfw", "dynect", "bigcouch" ], [ "iptables", "bigcouch::cluster_internal", "hosts", "rsyslog::client" ] }
sleep 5
$threads[:db003] = Thread.new { deploy_server "db003-staging-dfw", "BigCouch Node 3", "208.90.213.59", [ "staging", "rvm", "dfw", "dynect", "bigcouch" ], [ "iptables", "bigcouch::cluster_internal", "hosts", "rsyslog::client" ] }
sleep 5

$threads[:apps001] = Thread.new { deploy_server "apps001-staging-dfw", "App Server 1", "208.90.213.55", [ "staging", "rvm", "dfw", "dynect", "whistle-apps-rpm" ], [ "iptables", "hosts", "whistle::dth", "logrotate::opensip", "opensips", "haproxy::bigcouch_lb" ] }
sleep 5
$threads[:apps002] = Thread.new { deploy_server "apps002-staging-dfw", "App Server 2", "208.90.213.56", [ "staging", "rvm", "dfw", "dynect", "whistle-apps-rpm" ], [ "iptables", "hosts", "whistle::dth", "logrotate::opensip", "opensips", "haproxy::bigcouch_lb" ] }
sleep 5
$threads[:fs001] = Thread.new { deploy_server "fs001-staging-dfw", "FreeSWITCH 1", "208.90.213.60", [ "staging", "rvm", "dfw", "dynect", "whistle-fs" ], [ "hosts", "iptables" ] }
sleep 5
$threads[:fs002] = Thread.new { deploy_server "fs002-staging-dfw", "FreeSWITCH 2", "208.90.213.61", [ "staging", "rvm", "dfw", "dynect", "whistle-fs" ], [ "hosts", "iptables" ] }
sleep 5

$threads.each do |name,thread|
  $log.debug "Waiting for #{name} to finish"
  thread.join(14400)
end

$log.info "Deployment Complete."
time_finished = Time.new
elapsed = time_finished.to_f - time_started.to_f
minutes, seconds = elapsed.divmod 60.0
hours, minutes = minutes.divmod 60.0
$log.info "Time to finish: #{hours.to_i} hours, #{minutes.to_i} minutes, #{seconds.to_i} seconds"

