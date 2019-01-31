module FaaStRuby
  class FunctionObject
    include RunnerMethods
    attr_reader :path
    def initialize(path)
      @path = path
    end
  end
end