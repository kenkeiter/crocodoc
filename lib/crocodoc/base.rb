require "bundler/setup"

require "mime/types"
require "faraday"
require "faraday_middleware"
require "multi_json"

module Crocodoc

  # :nodoc:
  class Error < StandardError; end

  # Get the path to the SSL CA cert file
  def self.ssl_ca_cert_path
    @ssl_ca_cert_path ||= File.join(File.dirname(__FILE__), 'certs/ca-bundle.crt')
  end

  # Set the path to the SSL CA cert file that will be used.
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

  # Set the Faraday connection adapter to use (along with any arguments) for 
  # the transaction.
  def self.connection_adapter=(args)
    @connection_adapter = args
    @connection = nil # invalidate the current Faraday instance
  end

  # Change the debugging status. Should be set to true or false.
  def self.debug=(debug)
    @debug = debug
  end

  # Check if debugging is enabled.
  def self.debug?
    !!@debug || false
  end

  # The +APIError+ exception is raised whenever an error occurs on the 
  # server side.
  class APIError < StandardError; end

  # The +APIRequestError+ exception is raised whenever a faulty request is 
  # made to the server.
  class APIRequestError < StandardError; end

  # The +InvalidTokenError+ exception is raised when the server denies access 
  # to the API because the token is invalid.
  class InvalidTokenError < StandardError; end

  # Get a reference to the current Faraday connection object.
  def self.connection
    unless @connection
      @connection ||= Faraday.new(base_url, :ssl => {:ca_file => ssl_ca_cert_path}) do |conn|
        conn.request :include_token, self.api_token
        conn.request :multipart
        conn.request :url_encoded

        conn.response :crocodoc_response
        conn.response :json, :content_type => /\bjson$/
        conn.response :logger if debug?
        
        if @connection_adapter
          conn.adapter *@connection_adapter
        else
          conn.adapter :net_http
        end
      end
    end
    return @connection
  end

end