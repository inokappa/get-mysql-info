#!/usr/bin/env ruby 
require 'rubygems'
require 'terminal-table'
require 'net/ssh'
require 'json'


# connect via ssh to mysql server
class Con
  def initialize(host,user,password)
    @host = host
    @user = user 
    @password = password
  end
  def ssh_exec(command)
    ssh = Net::SSH.start(@host, @user, :password => @password) 
    ssh.exec! command
  end
end

class Mysqlinfo < Con
  def get_os_name
    os_raw = ssh_exec("uname -s")
    os = os_raw.strip
  end
  def get_os_mem
    os_raw = ssh_exec("uname -s")
    if os_raw == "FreeBSD\n"
      mem_raw = ssh_exec("grep memory /var/run/dmesg.boot | egrep 'real|usable' | awk '{print $5,$6}'")
    else
      mem_raw = ssh_exec("cat /proc/meminfo  | grep MemTotal | awk '{print $2,$3}'")
    end
    mem = mem_raw.strip
  end
  def get_wait_timeout(myuser,mypass)
    wait_timeout_raw = ssh_exec("mysql -u#{myuser} -p#{mypass} --execute='show variables' | egrep '^wait_timeout' | sed s/wait_timeout//g")
    wait_timeout = wait_timeout_raw.strip
  end
  def get_thread_cache_size(myuser,mypass)
    thread_cache_size_raw = ssh_exec("mysql -u#{myuser} -p#{mypass} --execute='show variables' | egrep '^thread_cache_size' | sed s/thread_cache_size//g")
    thread_cache_size = thread_cache_size_raw.strip
  end
  def get_max_connection(myuser,mypass)
    max_connection_raw = ssh_exec("mysql -u#{myuser} -p#{mypass} --execute='show variables' | egrep '^max_connections' | sed s/max_connections//g")
    max_connection = max_connection_raw.strip
  end
  def get_innodb_buffer_pool_size(myuser,mypass)
    innodb_buffer_pool_size_raw = ssh_exec("mysql -u#{myuser} -p#{mypass} --execute='show variables' | egrep '^innodb_buffer_pool_size'| sed s/innodb_buffer_pool_size//g")
    if innodb_buffer_pool_size_raw == nil
      innodb_buffer_pool_size = "N/A"
    else
      innodb_buffer_pool_size = innodb_buffer_pool_size_raw.strip
    end
  end
  def get_mysql_version(myuser,mypass)
    version_raw = ssh_exec("mysql -u#{myuser} -p#{mypass} --execute='show variables' | egrep '^version'| grep -v 'version_' | sed s/version//g")
    version = version_raw.strip
  end
end
#
rows = []
filename = "./server_info"
file = open(filename)
while text = file.gets do
  raw = text
  arr = raw.split(",")
  chk = Mysqlinfo.new("#{arr[0]}","#{arr[1]}","#{arr[2]}")
  myuser = "#{arr[3]}"
  mypass = "#{arr[4]}"
  rows << [\
    "#{arr[0]}",\
    "#{chk.get_os_name}",\
    "#{chk.get_os_mem}",\
    "#{chk.get_mysql_version(myuser,mypass)}",\
    "#{chk.get_wait_timeout(myuser,mypass)}",\
    "#{chk.get_thread_cache_size(myuser,mypass)}",\
    "#{chk.get_max_connection(myuser,mypass)}",\
    "#{chk.get_innodb_buffer_pool_size(myuser,mypass)}"]

  table = Terminal::Table.new :headings => [\
    'Host',\
    'OS',\
    'Memory',\
    'MySQL version',\
    'wait_timeout',\
    'thread_cache_size',
    'max_connection',
    'innodb_buffer_pool_size'], :rows => rows
end
#
puts table
