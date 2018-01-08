module ActiveResourceMockHelper
  def required_headers
    {
      'Accept' => 'application/json',
      'Authorization' => 'Token token=workerkey'
    }
  end
end
