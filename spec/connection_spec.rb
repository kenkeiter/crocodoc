require 'spec_helper'

describe "Crocodoc#request" do

  before :all do
    stub_request_testing_urls
  end

  it 'should support multiple response types' do
    # default response_type is JSON
    response = Crocodoc.connection.get '/json'
    response.body.should == STUB_JSON_RESPONSE

    # specify a JSON response type
    response = Crocodoc.connection.get '/json'
    response.body.should eq(STUB_JSON_RESPONSE)

    # specify a raw response type
    response = Crocodoc.connection.get '/raw'
    response.body.should eq(STUB_RAW_CONTENT)
  end

  it 'should raise corresponding exceptions when HTTP errors are encountered' do
    expect { Crocodoc.connection.get '/error/400' }.to raise_error(ArgumentError)
    expect { Crocodoc.connection.get '/error/401' }.to raise_error(Crocodoc::InvalidTokenError)
    expect { Crocodoc.connection.get '/error/404' }.to raise_error(Crocodoc::APIRequestError)
    expect { Crocodoc.connection.get '/error/405' }.to raise_error(Crocodoc::APIRequestError)
    expect { Crocodoc.connection.get '/error/500' }.to raise_error(Crocodoc::APIError)
  end

  it 'should include the API token as a parameter in all requests' do
    response = Crocodoc.connection.get '/verify_token'
    response.body.should eq(STUB_API_TOKEN)
  end

end