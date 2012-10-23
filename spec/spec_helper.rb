require 'multi_json'
require 'faraday'
require 'crocodoc'
require 'tempfile'

STUB_API_TOKEN = '123456'
STUB_UUID = '8e5b0721-26c4-11df-b354-002170de47d3'
STUB_SESSION_ID = 'CFAmd3Qjm_2ehBI7HyndnXKsDrQXJ7jHCuzcRv_V4FAgbSmaBkFrDRS8'\
                  'KX8m-Ur9MdZFbH3ykKdZ7cZswFqrDKX965nba9-MW0DiiA'
STUB_RAW_CONTENT = 'stub download content'
STUB_EXTRACTED_TEXT_CONTENT = "page 1\tpage 2\tpage 3"
STUB_JSON_RESPONSE = {'result' => true}.freeze
STUB_STATUS_VALUES = {}

def reset_api_status_reply
  STUB_STATUS_VALUES[:uuid] = STUB_UUID
  STUB_STATUS_VALUES[:status] = false
  STUB_STATUS_VALUES[:viewable] = false
  STUB_STATUS_VALUES[:error] = false
end

def set_api_status(opts)
  STUB_STATUS_VALUES.merge!(opts)
end

def json_response(obj)
  MultiJson.dump(obj)
end

REQUEST_STUBS = Faraday::Adapter::Test::Stubs.new do |stub|
  stub.get('/json'){ [200, {'Content-Type' => 'application/json'}, json_response(STUB_JSON_RESPONSE)] }
  stub.get('/raw'){ [200, {}, STUB_RAW_CONTENT] }
  stub.get('/error/400'){ [400, {}, STUB_RAW_CONTENT] }
  stub.get('/error/401'){ [401, {}, STUB_RAW_CONTENT] }
  stub.get('/error/404'){ [404, {}, STUB_RAW_CONTENT] }
  stub.get('/error/405'){ [405, {}, STUB_RAW_CONTENT] }
  stub.get('/error/500'){ [500, {}, STUB_RAW_CONTENT] }
  stub.get('/verify_token'){ |env| [200, {}, env[:params]['token']] }
end

API_STUBS = Faraday::Adapter::Test::Stubs.new do |stub|
  
  # Document Upload (https://crocodoc.com/docs/api/#doc-upload)
  stub.post('/api/v2/document/upload') do 
    [200, {'Content-Type' => 'application/json'}, json_response({:uuid => STUB_UUID})]
  end

  # Check document status (https://crocodoc.com/docs/api/#doc-status)
  stub.get('/api/v2/document/status') do |env|
    [200, {'Content-Type' => 'application/json'}, json_response([STUB_STATUS_VALUES])]
  end

  # Delete a document (https://crocodoc.com/docs/api/#doc-delete)
  stub.post('/api/v2/document/delete') do
    [200, {}, json_response(true)]
  end

  # Create a session (https://crocodoc.com/docs/api/#session-create)
  stub.post('/api/v2/session/create') do
    [200, {'Content-Type' => 'application/json'}, json_response({:session => STUB_SESSION_ID})]
  end

  # Download a document (https://crocodoc.com/docs/api/#dl-doc)
  stub.get('/api/v2/download/document') do
    [200, {}, STUB_RAW_CONTENT]
  end

  # Download a thumnail (https://crocodoc.com/docs/api/#dl-thumb)
  stub.get('/api/v2/download/thumbnail') do
    [200, {}, STUB_RAW_CONTENT]
  end

  # Download extracted text (https://crocodoc.com/docs/api/#dl-text)
  stub.get('/api/v2/download/text') do
    [200, {}, STUB_EXTRACTED_TEXT_CONTENT]
  end

end

# Set this to `true` to enable Faraday logging.
Crocodoc.debug = false

def stub_request_testing_urls
  Crocodoc.base_url = nil
  Crocodoc.api_token = STUB_API_TOKEN
  Crocodoc.connection_adapter = [:test, REQUEST_STUBS]
end

def stub_api_request_testing_urls
  Crocodoc.base_url = nil
  Crocodoc.api_token = STUB_API_TOKEN
  Crocodoc.connection_adapter = [:test, API_STUBS]
end
