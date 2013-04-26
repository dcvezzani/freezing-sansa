require 'rubygems'
require 'bundler/setup'
require 'net/https'
require "uri"
require 'yaml'

Bundler.require

class MySavon

  CONFIG = YAML::load(IO.read("config.yml"))

  NAMESPACES = {
    "xmlns" => "http://www.universityofcalifornia.edu/UCPath", 
    "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
    "xmlns:ns2" => "http://www.universityofcalifornia.edu/UCPath/IDM"
  }

  attr_accessor :client

  def initialize
    @client = Savon.client(
      #wsdl: "https://#{config[:wsdl][:domain]}:#{config[:wsdl][:port]}#{config[:wsdl][:path]}",
      wsdl: config[:wsdl][:path], 

      ssl_cert_file:         config[:certificate][:public], 
      ssl_cert_key_file:     config[:certificate][:private], 
      ssl_cert_key_password: config[:certificate][:password], 
      ssl_cert_store_files:  config[:certificate][:trusted], # trusted certificates in the store
      ssl_verify_mode: :fail_if_no_peer_cert, 
      ssl_version: :TLSv1, 

      pretty_print_xml: true, 
      log_level: :debug, 
      logger: Logger.new('savon.log'), 

      convert_request_keys_to: :none, 
      namespaces: MySavon::NAMESPACES, 
      env_namespace: :soap, 
      namespace_identifier: :ns2
    )
    puts client.operations

    return self
  end

  def config
    MySavon::CONFIG
  end

  def update_person_job
    formatted_xml = <<-EOL
          <ns2:PersonJobRecord>
            <ns2:Identifier>
              <EmplID>123456</EmplID>
            </ns2:Identifier>
          </ns2:PersonJobRecord>

          <ns2:PersonJobRecord>
            <ns2:Identifier>
              <EmplID>789012</EmplID>
            </ns2:Identifier>
          </ns2:PersonJobRecord>
    EOL

    xml = formatted_xml.gsub(/>\s+</, '><').gsub(/^\s+/, "").gsub(/\s+$/, "")

    response = client.call(:update_person_job, message: xml)

    return response.body[:uc_path_service_response]
  end

end

client = MySavon.new
puts client.update_person_job

=begin

# make call using straight soap xml:
# =====================================
formatted_xml = <<-EOL
<soap:Envelope xmlns="http://www.universityofcalifornia.edu/UCPath" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns2="http://www.universityofcalifornia.edu/UCPath/IDM">
  <soap:Body>
    <ns2:IDMPersonJobList>
      <ns2:PersonJobRecord>
        <ns2:Identifier>
          <EmplID>123456</EmplID>
        </ns2:Identifier>
      </ns2:PersonJobRecord>
      <ns2:PersonJobRecord>
        <ns2:Identifier>
          <EmplID>789012</EmplID>
        </ns2:Identifier>
      </ns2:PersonJobRecord>
    </ns2:IDMPersonJobList>
  </soap:Body>
</soap:Envelope>
EOL

xml = formatted_xml.gsub(/>\s+</, '><').gsub(/^\s+/, "").gsub(/\s+$/, "")
response = client.call(:update_person_job, xml: xml)


# make call using inner soap xml
# =====================================
formatted_xml = <<-EOL
      <ns2:PersonJobRecord>
        <ns2:Identifier>
          <EmplID>123456</EmplID>
        </ns2:Identifier>
      </ns2:PersonJobRecord>

      <ns2:PersonJobRecord>
        <ns2:Identifier>
          <EmplID>789012</EmplID>
        </ns2:Identifier>
      </ns2:PersonJobRecord>
EOL

xml = formatted_xml.gsub(/>\s+</, '><').gsub(/^\s+/, "").gsub(/\s+$/, "")

response = client.call(:update_person_job, message: xml)


# UCIDMServices
# =====================================
#:path: /Users/davidvezzani/ucmerced/ucpath-ws/ws/src/main/resources/wsdl/UCIDMServices/UCIDMServices.wsdl

update_person_job
update_poi
update_department
update_job_code


# IDMServices
# =====================================
# :path: /Users/davidvezzani/ucmerced/ucpath-ws/ws/src/main/resources/wsdl/IDMServices/IDMServices.wsdl

update_custom_ucid


# retrieve WSDL
# =====================================
export WGET_CONFIG="--secure-protocol TLSv1 --no-check-certificate --certificate certs/ucMercedUCPathClient.pub --certificate-type PEM --private-key certs/ucMercedUCPathClient.key --private-key-type PEM"

wget ${WGET_CONFIG} https://localhost:8443/UCPath-WS/IDMServices/IDMServices?wsdl
wget ${WGET_CONFIG} -O UCIDMServices.wsdl https://localhost:8443/UCPath-WS/IDMServices/UCIDMServices?wsdl


# References
# =====================================

# logging; set up a logger for Savon
http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html

# online html formatter
http://www.freeformatter.com/html-formatter.html#ad-output

=end
