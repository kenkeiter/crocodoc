module Crocodoc

  class DocumentCollection
    include Enumerable

    def initialize(documents = [])
      @last_update = nil
      @documents = Hash[documents.map{|doc| [doc.uuid, doc] }]
    end

    def update_statuses(opts = {})
      response = Crocodoc.connection.get 'document/status',
        :uuids => @documents.values.map{|doc| doc.uuid }.join(',')
      response.body.each do |resp|
        @documents[resp['uuid']].status = resp
      end
    end

    def [](uuid)
      @documents[uuid]
    end

    def remove_document(doc)
      @documents.delete_if{|document| document == doc }
    end

    def remove_document_by_uuid(uuid)
      @documents.delete(uuid)
    end

    def add_document(doc)
      @documents[doc.uuid] = doc
    end

    def add_document_by_uuid(uuid)
      @documents[uuid] = Document.new(uuid)
    end

    def <<(doc)
      @documents[doc.uuid] = doc
    end

    def each(&block)
      @documents.values.each &block
    end

    def count
      @documents.count
    end

    def length
      count
    end

  end

end