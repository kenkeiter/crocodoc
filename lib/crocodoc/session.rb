module Crocodoc

  # The ViewingSession class represents a viewing session for a single user and 
  # document. It supports three methods of configuration: passing of a hash raw 
  # of options to +#initialize+, passing a block to +#initialize+, or creation 
  # of an instance/calling configuration methods later.
  #
  # = Example
  #
  #   session = DocumentViewingSession.new(document, 
  #     :filter => :all,
  #     :editable => true
  #   )
  #   session.request_session! # => "someimpossiblylongsessionidstring"
  #

  class DocumentViewingSession

    SESSION_EXPIRATION = 3600

    DEFAULT_OPTIONS = {
      :allow_editing => false,
      :filter => [],
      :allow_admin => false,
      :allow_download => false,
      :copy_protect => true,
      :demo => false,
      :sidebar => :auto
    }

    def initialize(document, opts = {})
      @document = document
      @key = nil
      @options = DEFAULT_OPTIONS.merge(opts)
    end

    def key
      raise Error, "Could not retrieve session key." unless @key
      return @key
    end

    def valid?
      not @key.nil?
    end

    def editable?
      !!@options[:allow_editing]
    end

    def downloadable?
      !!@options[:allow_download]
    end

    def admin?
      !!@options[:allow_admin]
    end

    def copy_protected?
      !!@options[:copy_protect]
    end

    def annotation_visible?
      not ((@options[:filter].kind_of?(Symbol) and @options[:filter] == :none) or
          (@options[:filter].kind_of?(String) and @options[:filter] == 'none') or 
          (@options[:filter].kind_of?(Array) and @options[:filter].empty?))
    end

    def comments_visible?
      annotation_visible?
    end

    def users
      @options[:filter]
    end

    def annotations_and_comments
      @options[:filter]
    end

    def sidebar_hidden?
      @options[:sidebar] == :hidden
    end

    def sidebar_collapsed?
      @options[:sidebar] == :collapse
    end

    def sidebar_visible?
      @options[:visible] = :visible
    end

    def sidebar_auto?
      @options[:auto] = :auto
    end

    def demo?
      @options[:demo] = :demo
    end

    def seconds_remaining
      if @key.nil?
        raise Error, "Cannot calculate time remaining; session key has not "\
                     "yet been requested using #activate_for_user." 
      end
      SESSION_EXPIRATION - (Time.now - @creation_time)
    end

    def expired?
      seconds_remaining > 0
    end

    def to_json
      if @key.nil?
        raise Error, "Cannot convert to JSON; session key has not yet been "\
                     "requested using #activate_for_user." 
      end
      MultiJson.dump({
        :editable => editable?,
        :user => @options[:user],
        :admin => admin?,
        :downloadable => downloadable?,
        :copyprotected => copy_protected?,
        :demo => demo?,
        :sidebar => @options[:sidebar].to_s,
        :key => key
      })
    end

    def from_json(data)
      data = MultiJson.load(data)
      @key = data['key']
      @creation_time = data['creation_time']
      data.delete('key')
      data.delete('creation_time')
      @options = data
    end

    def activate_for_user(user_id, username, opts = {})
      @creation_time = Time.now.utc
      session_opts = @options.dup
      response = Crocodoc.connection.post 'session/create',
        :editable => editable?,
        :user => "#{user_id},#{username}",
        :admin => admin?,
        :downloadable => downloadable?,
        :copyprotected => copy_protected?,
        :demo => demo?,
        :sidebar => session_opts[:sidebar].to_s,
        :uuid => @document.uuid
      @key = response.body['session']
      return self
    end

  end

end