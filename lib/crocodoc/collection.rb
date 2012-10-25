module Crocodoc

  # The DocumentCollection class acts as a set of documents upon which you can 
  # perform all +Enumerable+ (http://ruby-doc.org/core-1.9.3/Enumerable.html) 
  # operations, as well as bulk status retrieval. Statuses can be retrieved in 
  # bulk by calling +DocumentCollection#update_statuses+, and will update all 
  # documents in the collection with their current status, which will be valid 
  # for +Document.status_update_threshold+ seconds.
  #
  # = Example
  #
  #   documents = DocumentCollection.new([document, document, ...])
  #   documents.update_statuses
  #   documents.each{|uuid, doc| puts "#{uuid} ready!" if doc.viewable? }
  #
  class DocumentCollection
    include Enumerable

    # Create a new DocumentCollection from an array of +Document+ instances.
    def initialize(documents = [])
      @last_update = nil
      @documents = Hash[documents.map{|doc| [doc.uuid, doc] }]
    end

    # Update the statuses of all documents in the collection using one request.
    def update_statuses(opts = {})
      response = Crocodoc.connection.get 'document/status',
        :uuids => @documents.values.map{|doc| doc.uuid }.join(',')
      response.body.each do |resp|
        @documents[resp['uuid']].status = resp
      end
    end

    # Retrieve a document from the collection by its UUID.
    def [](uuid)
      @documents[uuid]
    end

    # Given a document instance, remove any matching instances from the 
    # collection.
    def remove_document(doc)
      @documents.delete_if{|document| document == doc }
    end

    # Given a UUID, remove any matching documents from the collection.
    def remove_document_by_uuid(uuid)
      @documents.delete(uuid)
    end

    # Given a document instance, add it to the collection.
    def add_document(doc)
      @documents[doc.uuid] = doc
    end

    # Given a UUID, add a new document instance for it to the collection.
    def add_document_by_uuid(uuid)
      @documents[uuid] = Document.new(uuid)
    end

    # Add a document to the collection. Shorthand for +#add_document+.
    def <<(doc)
      @documents[doc.uuid] = doc
    end

    # Enumerate the documents in the collection.
    #
    # = Example
    #
    #   documents.each{|uuid, doc| do_something }
    def each(&block)
      @documents.values.each &block
    end

    # :nodoc:
    def count
      @documents.count
    end

    # :nodoc:
    def length
      count
    end

  end

end