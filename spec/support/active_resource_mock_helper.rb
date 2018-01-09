module ActiveResourceMockHelper
  def required_headers
    {
      'Accept' => 'application/json',
      'Authorization' => 'Token token=<YOUR_WORKER_KEY>'
    }
  end
end
