module Crocodoc

  # The +Document+ class represents a single Crocodoc document, and exposes 
  # various operations specific to that document, including the generation of 
  # viewing sessions.
  #
  # = Example
  #
  #   document = Crocodoc::Document.upload_file('/path/to/document.docx')
  #   while !document.viewable?
  #     sleep 10
  #   end
  #   session = document.viewing_session.activate_for_user(1000, "kenkeiter")
  #   viewing_url = document.get_viewing_url(session)
  #
  class Document

    # :nodoc:
    STATUSES = {
      false => :unknown,
      'QUEUED' => :queued,
      'DONE' => :done,
      'ERROR' => :error
    }.freeze

    # Get the number of seconds for which a memoized document status value 
    # will be considered valid. Default is 4 seconds, and can be configured 
    # globally using the +status_update_threshold=+ method.
    def self.status_update_threshold
      @status_update_threshold ||= 4
    end

    # Set the number of seconds for which a memoized document status value 
    # will be valid. Useful for rate-limiting.
    def self.status_update_threshold=(seconds)
      @status_update_threshold = seconds
    end

    # Given an absolute filesystem +path+ to a document of a valid type, with 
    # the proper file extension, upload the document to Crocodoc, and return a 
    # new representative +Document+ instance. 
    #
    # = Example
    #
    #   d = Document.upload_file('/my/file/path.docx') # => <Document instance>
    #   d.uuid # => 'E88A2EFB-0E61-4DBB-94C7-E30E5AAF13F4'
    #
    def self.upload_file(path)
      unless File.exist?(path)
        raise ArgumentError, "File does not exist at path: #{path}"
      end
      mime_type = MIME::Types.type_for(File.basename(path))
      response = Crocodoc.connection.post 'document/upload',
        :file => Faraday::UploadIO.new(path, mime_type)
      raise APIRequestError, response.body['error'] if response.body['error']
      return new(response.body['uuid'])
    end

    # Given a +url+ of a valid file, have Crocodoc fetch the document, convert, 
    # and store it. Returns a representative +Document+ instance. 
    def self.upload_url(url)
      response = Crocodoc.connection.post 'document/upload', :url => url
      raise APIRequestError, response.body[:error] if response.body[:error]
      return new(response.body['uuid'])
    end

    # Retrieve the UUID of the document.
    attr_reader :uuid

    # Given a valid document UUID, create a new Document instance. 
    def initialize(uuid)
      raise ArgumentError, "UUID must be string" unless uuid.kind_of?(String)
      @uuid = uuid
      @status = {:status => :unknown, :viewable => false, :updated => nil}
    end

    # Retrieve the status information for the document. Results will be 
    # memoized for +Document.status_update_threshold+ seconds during which 
    # successive calls to +Document#status+ will provide the same response; 
    # however, memoization can be ignored (forcing a new HTTP request) if 
    # the +memoized+ arg is +false+. 
    def status(memoize = true)
      if @status[:updated].nil? or not memoize or (memoize and not @status[:updated].nil? and 
        ((Time.now - @status[:updated]) >= self.class.status_update_threshold))
        response = Crocodoc.connection.get 'document/status', :uuids => @uuid
        response = response.body.first
        @status[:updated] = Time.now
        @status[:status] = STATUSES[response['status']]
        @status[:viewable] = response['viewable']
        @status[:error] = response['error'] if response.member?('error')
      end
      return @status
    end

    def status=(new_status)
      @status[:updated] = Time.now
      @status[:status] = STATUSES[new_status['status']]
      @status[:viewable] = new_status['viewable']
      @status[:error] = new_status['error'] if new_status.member?('error')
    end

    # Determine if the document is viewable.
    def viewable?
      !!status[:viewable]
    end

    # Determine if an error has occurred during document conversion. If not, 
    # this will return false; however, if an error HAS occurred, this will 
    # return a string containing simple error information.
    def error?
      status[:error] || false
    end

    # Determine if the document has been successfully converted.
    def converted?
      status[:status] == :done
    end

    # Delete the document; returns a +Boolean+ indicating success.
    def delete(opts = {})
      response = Crocodoc.connection.post 'document/delete', :uuid => @uuid
      response.body.chomp.downcase == 'true'
    end

    # Given a writable destination path (+dest_path+), and optional +max_x+ and 
    # +max_y+ dimensions, download a thumbnail image of the doucment. Note that 
    # +max_x+ and +max_y+ cannot be more than 300 pixels each. The downloaded 
    # thumbnail will be a PNG image.
    def download_thumbnail(dest_path, max_x = 100, max_y = 100)
      response = Crocodoc.connection.get 'download/thumbnail',
        :uuid => @uuid,
        :size => "#{max_x}x#{max_y}"
      File.open(dest_path, 'wb') { |fp| fp.write(response.body) }
    end

    # Given a writable destination path (+dest_path+), download a copy of the 
    # original document, in its original format, without annotations.
    def download(dest_path)
      response = Crocodoc.connection.get 'download/document',
        :pdf => false,
        :annotated => false,
        :uuid => @uuid
      File.open(dest_path, 'wb') { |fp| fp.write(response.body) }
    end

    # Given a writable destination path (+dest_path+) download a PDF version of 
    # the document. Optionally, an +annotations+ parameter can be provided 
    # whose values can be 'all', 'none', or an array of user IDs for which 
    # annotations will be included in the exported PDF.
    def download_as_pdf(dest_path, annotations = false)
      annotations = annotations.join(',') if annotations.kind_of?(Enumerable)
      response = Crocodoc.connection.get 'download/document',
        :pdf => true,
        :annotated => !!annotations,
        :filter => annotations,
        :uuid => @uuid
      File.open(dest_path, 'wb') { |fp| fp.write(response.body) }
    end

    # If your account supports text extraction, retrieve the extracted text 
    # from the document. Extracted text will automatically be split by page and 
    # returned as an array. 
    def extracted_text
      response = Crocodoc.connection.get 'download/text', :uuid => @uuid
      return response.body.split("\f")
    end

    # Create a new +ViewingSession+ instance for this document. See 
    # +ViewingSession+ documentation for more details.
    def viewing_session(opts = {})
      Crocodoc::DocumentViewingSession.new(self, opts)
    end

    # Given a +ViewingSession+ instance, get a viewing URL for the document.
    def get_viewing_url(session)
      "https://crocodoc.com/view/#{session.key}"
    end

  end

end