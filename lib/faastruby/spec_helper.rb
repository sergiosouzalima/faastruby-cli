$LOAD_PATH << Dir.pwd
module FaaStRuby
  require 'faastruby/server/errors'
  require 'faastruby/server/runner_methods'
  require 'faastruby/server/event'
  require 'faastruby/server/response'
  ##########
  # Add call method to the Response class
  # for backwards compatibility.
  # This will be removed on v0.6
  class Response
    def call
      self
    end
  end
  # Add default initialize values to the
  # Event class for backwards compatibility.
  # This will be removed on v0.6
  class Event
    def initialize(body: nil, query_params: {}, headers: {}, context: nil)
      @body = body
      @query_params = query_params
      @headers = headers
      @context = context
    end
  end
  #########
  module SpecHelper
    include FaaStRuby
    include RunnerMethods
    def publish(channel, data: nil)
      true
    end
  end
end