require 'rubygems'
require 'bundler/setup'
require 'net/https'
require "uri"
require 'yaml'

Bundler.require

config = YAML::load(IO.read("config.yml"))

http = Net::HTTP.new(config[:wsdl][:domain], config[:wsdl][:port])
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT

# didn't hurt, but didn't seem to do anything either
store = OpenSSL::X509::Store.new
store.set_default_paths # Optional method that will auto-include the system CAs.
config[:certificate][:trusted].each do |trusted_certificate|
  store.add_cert(OpenSSL::X509::Certificate.new(File.read(trusted_certificate)))
end
http.cert_store = store

http.key = OpenSSL::PKey::RSA.new(File.read(config[:certificate][:private]), config[:certificate][:password])
http.cert = OpenSSL::X509::Certificate.new(File.read(config[:certificate][:public]))

response = http.request(Net::HTTP::Get.new(config[:wsdl][:path]))


