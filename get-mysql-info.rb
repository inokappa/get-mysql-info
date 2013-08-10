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
    rets = []
    rets << @host
    args.each do |params|
     params.each do |param|
      if !(param == "variables")
        exec = ssh_exec("mysql -u#{myuser} -p#{mypass} --execute='show variables' | egrep '^#{param}' | sed 's/#{param}//g'")
        if exec == nil
          rets << ["#{param}" => "N/A"]
        else
          rets << ["#{param}" => "#{exec}".strip!]
        end
      end
     end
     return rets 
    end
  end
end

#
filename = './server_info'
file = open(filename)
while text = file.gets do
  arr = text.split(",")
  chk = Mycommand.new("#{arr[0]}","#{arr[1]}","#{arr[2]}")
  myuser = "#{arr[3]}"
  mypass = "#{arr[4]}"
  rets = chk.mysql_variables_com(myuser,mypass,ARGV)
  rets.to_json(:root => false)
  json = JSON.pretty_generate([rets])
  puts json
end
