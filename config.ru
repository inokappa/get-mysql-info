require 'rubygems'
require 'sinatra'
require 'net/ssh'
require 'json'
require './get-mysql-info.rb'
 
run Sinatra::Application
