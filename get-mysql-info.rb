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

# 
class Mycommand < Con
  def mysql_variables_com(myuser,mypass,*args)
    my_rets = []
    args.each do |params|
     params.each do |param|
      if !(param == "variables")
        exec = ssh_exec("mysql -u#{myuser} -p#{mypass} --execute='show variables' | egrep '^#{param}' | sed 's/#{param}//g'")
        if exec == nil
          my_rets << ["#{param}" => "N/A"]
        else
          my_rets << ["#{param}" => "#{exec}".strip!]
        end
      end
     end
     return my_rets 
    end
  end
  def server_status
    os_rets = []
    os_raw = ssh_exec("uname -s")
    if os_raw == "FreeBSD\n"
      mem_raw = ssh_exec("grep memory /var/run/dmesg.boot | egrep 'real|usable' | awk '{print $5,$6}'")
    else
      mem_raw = ssh_exec("cat /proc/meminfo  | grep MemTotal | awk '{print $2,$3}'")
    end
    os_rets << ["OS" => "#{os_raw}".strip!]
    os_rets << ["Mem" => "#{mem_raw}".strip!]
  end
end
#
filename = './server_info'
file = open(filename)
result = []
while text = file.gets do
  arr = text.split(",")
  chk = Mycommand.new("#{arr[0]}","#{arr[1]}","#{arr[2]}")
  myuser = "#{arr[3]}"
  mypass = "#{arr[4]}"
  my_rets = chk.mysql_variables_com(myuser,mypass,ARGV)
  os_rets = chk.server_status
  result << "#{arr[0]}"
  result << os_rets
  result << my_rets
  puts result
  #result.to_json(:root => false)
  #json = JSON.pretty_generate([result])
  #puts json
end
