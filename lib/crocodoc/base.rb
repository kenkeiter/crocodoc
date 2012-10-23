require "bundler/setup"

require "mime/types"
require "faraday"
require "faraday_middleware"
require "multi_json"

module Crocodoc

  # :nodoc:
  class Error < StandardError; end

  def self.ssl_ca_cert_path
    @ssl_ca_cert_path ||= File.join(File.dirname(__FILE__), 'certs/ca-bundle.crt')
  end

  def self.ssl_ca_cert_path=(path)
    raise Error, "No SSL CA cert file at #{path}" unless File.exist?(path)
    @ssl_ca_cert_path = path
  end

  # Get the API endpoint base URL.
  def self.base_url
    @base_url ||= "https://crocodoc.com/api/v2"
  end

  # Set the API endpoint base URL.
  def self.base_url=(url)
    @base_url = url
    @connection = nil # invalidate the current Faraday instance
  end

  # Set the API token with which to make requests. This must be set before 
  # making any requests.
  def self.api_token=(token)
    @api_token = token
    @connection = nil # invalidate the current Faraday instance
  end

  # Retrieve the API token with which to make requests. This will raise an 
  # exception if no token is set.
  def self.api_token
    unless @api_token
      raise Error, "No API token specified. Use Crocodoc#api_token= method."
    end
    return @api_token
  end

  def self.connection_adapter=(args)
    @connection_adapter = args
    @connection = nil # invalidate the current Faraday instance
  end

  def self.debug=(debug)
    @debug = debug
  end

  def self.debug?
    @debug || false
  end

end