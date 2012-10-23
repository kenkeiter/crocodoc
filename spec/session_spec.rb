require 'spec_helper'

describe Crocodoc::DocumentViewingSession do

  before :all do 
    stub_api_request_testing_urls
  end

  context "not activated" do

    before :each do
      @document = Crocodoc::Document.new(STUB_UUID)
      @session = Crocodoc::DocumentViewingSession.new(@document)
    end

    it "should have a set of safe defaults" do
      @session.editable?.should be_false
      @session.annotation_visible?.should be_false
      @session.comments_visible?.should be_false
      @session.users.should be_empty
      @session.valid?.should be_false
    end

    it "should not provide seconds remaining" do
      expect { @session.expired? }.to raise_error(Crocodoc::Error)
    end

    it "should retrieve a key for a user" do
      @session.activate_for_user(1000, 'Ken Keiter')
      @session.key.should == STUB_SESSION_ID
    end

  end

  before :each do
    @document = Crocodoc::Document.new(STUB_UUID)
    @session = Crocodoc::DocumentViewingSession.new(@document)
    @session.activate_for_user(1000, "Ken Keiter")
  end

  # TODO: Fix this so that it ACTUALLY tests JSON output.
  it "should be serializable to JSON" do
    @session.should respond_to(:to_json)
    expect{ @session.to_json }.to_not raise_error(Crocodoc::Error)
  end

  it "should be hydratable from JSON" do
    @session.should respond_to(:from_json)
    test_document = Crocodoc::Document.new(STUB_UUID)
    test_session = Crocodoc::DocumentViewingSession.new(test_document)
    test_session.activate_for_user(1000, "Ken Keiter")
    test_session.to_json.should == @session.to_json
  end

end