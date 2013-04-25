require 'rubygems'
require 'bundler/setup'
require 'net/https'
require "uri"
require 'yaml'

Bundler.require

config = YAML::load(IO.read("config.yml"))

client = Savon.client(
  wsdl: "https://#{config[:wsdl][:domain]}:#{config[:wsdl][:port]}#{config[:wsdl][:path]}",
  ssl_cert_file:         config[:certificate][:public], 
  ssl_cert_key_file:     config[:certificate][:private], 
  ssl_cert_key_password: config[:certificate][:password], 
  ssl_cert_store_files:  config[:certificate][:trusted], # trusted certificates in the store
  ssl_verify_mode: :fail_if_no_peer_cert, 
  ssl_version: :TLSv1
)

puts client.operations
