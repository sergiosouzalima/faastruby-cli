require 'base64'
require 'open3'
module FaaStRuby
  class Runner
    include RunnerMethods
    def initialize
      @rendered = false
    end

    def path
      @path
    end
    
    def load_function(path)
      eval "Module.new do; #{File.read(path)};end"
    end

    def call(workspace_name, function_name, event, args)
      @short_path = "#{workspace_name}/#{function_name}"
      @path = "#{FaaStRuby::PROJECT_ROOT}/#{workspace_name}/#{function_name}"
      begin
        Dir.chdir(@path)
        runtime, version = (YAML.load(File.read('faastruby.yml'))['runtime'] || 'ruby:2.5.3').split(':')
        case runtime
        when 'ruby'
          response = call_ruby(event)
        when 'crystal'
          response = call_crystal(event)
        else
          puts "[Runner] ERROR: could not determine runtime for function #{@short_path}.".red
        end
        return response if response.is_a?(FaaStRuby::Response)
        body = {
          'error' => "Please use the helpers 'render' or 'respond_with' as your function return value."
        }
        FaaStRuby::Response.new(body: Oj.dump(body), status: 500, headers: {'Content-Type' => 'application/json'})
      rescue Exception => e
        STDOUT.puts e.full_message
        body = {
          'error' => e.message,
          'location' => e.backtrace&.first,
        }
        FaaStRuby::Response.new(body: Oj.dump(body), status: 500, headers: {'Content-Type' => 'application/json'})
      end
    end
    def call_ruby(event)
      function = load_function("#{@path}/handler.rb")
      runner = FunctionObject.new(@short_path)
      runner.extend(function)
      response = runner.handler(event, *args)
    end

    def call_crystal(event)
      ####
      # This is a hack to address the bug https://github.com/crystal-lang/crystal/issues/7052
      event.query_params.each do |k, v|
        event.query_params[k] = '' if v.nil?
      end
      event.headers.each do |k, v|
        event.headers[k] = '' if v.nil?
      end
      ####
      payload_json = Oj.dump({'event' => event.to_h, 'args' => []})
      payload = Base64.urlsafe_encode64(payload_json, padding: false)
      cmd = "#{@path}/handler"
      # STDOUT.puts "Running #{cmd}"
      output = nil
      Open3.popen2(cmd) do |stdin, stdout, status|
        stdin.puts payload
        stdout.each_line do |line|
          if line[0..1] == 'R,'
            output = line.chomp
            break
          else
            puts line.chomp
          end
        end
      end
      tag, o = output.split(',')
      decoded_response = Base64.urlsafe_decode64(o)
      response_obj = Oj.load(decoded_response)
      # STDOUT.puts response_obj
      FaaStRuby::Response.new(
        body: response_obj['response'],
        status: response_obj['status'],
        headers: response_obj['headers']
      )
    end
  end
end