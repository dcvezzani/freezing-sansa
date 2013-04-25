require 'rubygems'
require 'bundler/setup'
require 'net/https'
require "uri"
require 'yaml'

Bundler.require

config = YAML::load(IO.read("config.yml"))

request = HTTPI::Request.new("https://#{config[:wsdl][:domain]}:#{config[:wsdl][:port]}#{config[:wsdl][:path]}")

request.auth.ssl.cert_key_file     = config[:certificate][:private]   # the private key file to use
request.auth.ssl.cert_key_password = config[:certificate][:password]  # the key file's password
request.auth.ssl.cert_file         = config[:certificate][:public]    # the certificate file to use
request.auth.ssl.cert_store_files  = config[:certificate][:trusted]   # trusted certificates in the store
request.auth.ssl.verify_mode       = :fail_if_no_peer_cert            # or one of [:peer, :fail_if_no_peer_cert, :client_once]
request.auth.ssl.ssl_version       = :TLSv1                           # or one of [:SSLv2, :SSLv3]

response = HTTPI.get(request)

