module Crocodoc

  # The +APIError+ exception is raised whenever an error occurs on the 
  # server side.
  class APIError < StandardError; end

  # The +APIRequestError+ exception is raised whenever a faulty request is 
  # made to the server.
  class APIRequestError < StandardError; end

  # The +InvalidTokenError+ exception is raised when the server denies access 
  # to the API because the token is invalid.
  class InvalidTokenError < StandardError; end

  # Get a reference to the current Faraday connection object. If a block is 
  # given, a new Faraday connection will be created, replacing the primary, 
  # and the block will be used to configure it.
  #
  # = Example
  #
  #   Crocodoc.connection do |conn|
  #     conn.adapter :excon
  #   end
  #
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