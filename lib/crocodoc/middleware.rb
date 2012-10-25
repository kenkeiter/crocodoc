module Crocodoc
  module Middleware

    # :nodoc:
    class IncludeToken < ::Faraday::Middleware

      def initialize(app, token)
        super(app)
        @token = token
      end

      def call(env)
        unless env[:method] == :get or env[:method] == :delete
          env[:body] ||= {}
          env[:body] = env[:body].merge(:token => @token)
        else
          # FARADAY Y U NO LEAVE MY QUERY PARAMS ALONE?!!
          query = env[:url].query.nil? ? {} : Faraday::Utils.parse_query(env[:url].query)
          env[:url].query = Faraday::Utils.build_query(query.merge(:token => @token))
        end
        @app.call(env)
      end

    end

    # :nodoc:
    class CrocodocResponse < ::Faraday::Response::Middleware

      def call(env)
        @app.call(env).on_complete do |response|
          case response[:status].to_i
          when 400
            raise ArgumentError, "400 Bad Request: Invalid request parameters :: #{response[:body]}"
          when 401
            raise ::Crocodoc::InvalidTokenError, "401 Unauthorized: Invalid API token."
          when 404
            raise ::Crocodoc::APIRequestError, "404: API method not found"
          when 405
            raise ::Crocodoc::APIRequestError, "405 Method Not Allowed: Invalid HTTP request type for method."
          when (500..599)
            raise ::Crocodoc::APIError, "#{response[:status]} Server Error"
          end
        end
      end

    end

  end

  # Register middlewarez

  Faraday.register_middleware :request,
    :include_token => lambda{ Middleware::IncludeToken }

  Faraday.register_middleware :response,
    :crocodoc_response => lambda{ Middleware::CrocodocResponse }

end