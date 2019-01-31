module FaaStRuby
  class Response
    def self.request_limit_reached(workspace: nil, function: nil)
      body = {'error' => "Concurrent requests limit reached. Please add more runners to the workspace #{workspace}."} if workspace
      # body = {'error' => "Concurrent requests limit reached for function '#{workspace}/#{function}'. Please associate more runners."} if function
      body = Oj.dump(body)
      new(
        body: body,
        status: 422,
        headers: {'Content-Type' => 'application/json'}
      )
    end
    attr_accessor :body, :status, :headers, :binary
    def initialize(body:, status: 200, headers: {}, binary: false)
      @body = body
      @status = status
      @headers = headers
      @binary = binary
    end

    def binary?
      @binary
    end
  end
end