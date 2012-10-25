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

    # Non-configurable session expiration, managed by Crocodoc's servers.
    SESSION_EXPIRATION = 3600

    # :nodoc:
    DEFAULT_OPTIONS = {
      :allow_editing => false,
      :filter => [],
      :allow_admin => false,
      :allow_download => false,
      :copy_protect => true,
      :demo => false,
      :sidebar => :auto
    }

    # Create a new DocumentViewingSession instance, given a document object and 
    # set of default options.
    def initialize(document, opts = {})
      @document = document
      @key = nil
      @options = DEFAULT_OPTIONS.merge(opts)
    end

    # Get the document key.
    def key
      raise Error, "Could not retrieve session key." unless @key
      return @key
    end

    # Determine if the document viewing session is valid. This does not take 
    # expiration into account, because it may not be valid after hydration.
    def valid?
      not @key.nil?
    end

    # Determine if the session has edit permissions.
    def editable?
      !!@options[:allow_editing]
    end

    # Determine if the session allows downloading.
    def downloadable?
      !!@options[:allow_download]
    end

    # Determine if the session has administrative privileges.
    def admin?
      !!@options[:allow_admin]
    end

    # Determine if copy protection is enabled for the session.
    def copy_protected?
      !!@options[:copy_protect]
    end

    # Determine if any annotation is visible in the session.
    def annotation_visible?
      not ((@options[:filter].kind_of?(Symbol) and @options[:filter] == :none) or
          (@options[:filter].kind_of?(String) and @options[:filter] == 'none') or 
          (@options[:filter].kind_of?(Array) and @options[:filter].empty?))
    end

    # Check if comments are visible?
    def comments_visible?
      annotation_visible?
    end

    # Determine which users have access to the document.
    def users
      @options[:filter]
    end

    def annotations_and_comments
      @options[:filter]
    end

    # Determine if the sidebar is hidden.
    def sidebar_hidden?
      @options[:sidebar] == :hidden
    end

    # Determine if the sidebar is collapsed.
    def sidebar_collapsed?
      @options[:sidebar] == :collapse
    end

    # Determine if the sidebar is visible.
    def sidebar_visible?
      @options[:visible] = :visible
    end

    # Determine if the sidebar should be shown automatically.
    def sidebar_auto?
      @options[:auto] = :auto
    end

    # Determine if this is a demo session. If so, annotations and changes will 
    # not be persisted when the session ends.
    def demo?
      @options[:demo] = :demo
    end

    # Determine the number of seconds remaining in the session. Note that this 
    # value is determined locally; not on the remote server. Typically, 
    # sessions expire 60 minutes from their start.
    def seconds_remaining
      if @key.nil?
        raise Error, "Cannot calculate time remaining; session key has not "\
                     "yet been requested using #activate_for_user." 
      end
      SESSION_EXPIRATION - (Time.now - @creation_time)
    end

    # Determine if the session has expired (see 
    # +DocumentViewingSession#seconds_remaining+ for more information.
    def expired?
      seconds_remaining > 0
    end

    # Convert a viewing session to JSON.
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

    # Load a viewing session's parameters from JSON.
    def from_json(data)
      data = MultiJson.load(data)
      @key = data['key']
      @creation_time = data['creation_time']
      data.delete('key')
      data.delete('creation_time')
      @options = data
    end

    # Finalize the viewing session's parameters, and send a request to the 
    # server for a viewing session key.
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