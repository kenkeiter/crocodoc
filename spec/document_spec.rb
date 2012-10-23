require 'spec_helper'

describe Crocodoc::Document do

  before :all do
    stub_api_request_testing_urls
  end

  context "class" do

    it 'should allow files to be uploaded' do
      # create a temporary file to upload.
      file_to_upload = Tempfile.new('document')
      file_to_upload.write(STUB_RAW_CONTENT)
      file_to_upload.close

      # "upload" the file
      document = Crocodoc::Document.upload_file(file_to_upload.path)

      # verify the response
      document.should be_kind_of(Crocodoc::Document)
      document.uuid.should eq(STUB_UUID)

      # clean up!
      file_to_upload.unlink
    end

    it 'should allow URLs to uploaded' do
      document = Crocodoc::Document.upload_url("http://example.com/")
      document.should be_kind_of(Crocodoc::Document)
      document.uuid.should eq(STUB_UUID)
    end

    it 'should allow a status update threshold to be set/retrieved' do
      Crocodoc::Document.status_update_threshold = 3
      Crocodoc::Document.status_update_threshold.should eql(3)
    end

  end

  context "instance" do

    before :all do
      stub_api_request_testing_urls
      reset_api_status_reply
      @document = Crocodoc::Document.new(STUB_UUID)
    end

    it 'should have a unique identifier' do
      @document.uuid.should eql(STUB_UUID)
    end

    it 'should memoize status information for a given time period' do
      Crocodoc::Document.status_update_threshold = 0.5
      status = @document.status.dup
      set_api_status(:viewable => true)
      @document.status.should == status
      sleep(Crocodoc::Document.status_update_threshold)
      @document.status.should_not == status
    end

    it 'should provide simple status accessors' do
      Crocodoc::Document.status_update_threshold = 0
      set_api_status(:viewable => true)
      @document.viewable?.should be_true
      set_api_status(:error => 'some error')
      @document.error?.should == 'some error'
      set_api_status(:status => 'DONE')
      @document.converted?.should be_true
    end

    it 'should be deletable' do
      @document.delete.should be(true)
    end

    it 'should allow a thumbnail to be downloaded' do
      thumnail_file = Tempfile.new('thumbnail')
      @document.download_thumbnail(thumnail_file.path)
      thumnail_file.rewind
      thumnail_file.read.should == STUB_RAW_CONTENT
      thumnail_file.unlink
    end

    it 'should allow the original document to be downloaded' do
      document_file = Tempfile.new('document')
      @document.download(document_file.path)
      document_file.rewind
      document_file.read.should == STUB_RAW_CONTENT
      document_file.unlink
    end

    it 'should allow a PDF of the document to be downloaded' do
      pdf_file = Tempfile.new('pdf_document')
      @document.download(pdf_file.path)
      pdf_file.rewind
      pdf_file.read.should == STUB_RAW_CONTENT
      pdf_file.unlink
    end

    it 'should allow allow text extracted from the document to be retrieved' do 
      @document.extracted_text.should == STUB_EXTRACTED_TEXT_CONTENT.split("\r")
    end

    it 'should allow a viewing session to be created' do
      @document.viewing_session.should be_kind_of(Crocodoc::DocumentViewingSession)
    end

    it 'given a session, should provide a viewing url' do
      session = @document.viewing_session.activate_for_user(1000, 'Ken Keiter')
      session.should be_kind_of(Crocodoc::DocumentViewingSession)
      session.key.should == STUB_SESSION_ID
      @document.get_viewing_url(session).should == "https://crocodoc.com/view/#{STUB_SESSION_ID}"
    end

  end

end