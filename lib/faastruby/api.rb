require 'rest-client'

module FaaStRuby
  class API
    @@api_version = 'v2'
    attr_reader :api_url, :credentials, :headers
    def initialize
      @api_url = "#{FaaStRuby.api_host}/#{@@api_version}"
      @credentials = {'API-KEY' => FaaStRuby.api_key, 'API-SECRET' => FaaStRuby.api_secret}
      @headers = {content_type: 'application/json', accept: 'application/json'}.merge(@credentials)
      @struct = Struct.new(:response, :body, :errors, :code)
      @timeout = nil # disable request timeouts
    end

    def create_workspace(workspace_name:, email: nil, provider: nil)
      url = "#{@api_url}/workspaces"
      payload = {'name' => workspace_name}
      payload['email'] = email if email
      payload['provider'] = provider if provider
      parse RestClient::Request.execute(method: :post, timeout: @timeout, url: url, payload: Oj.dump(payload), headers: @headers)
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        parse err.response
      end
    end

    def destroy_workspace(workspace_name)
      url = "#{@api_url}/workspaces/#{workspace_name}"
      parse RestClient::Request.execute(method: :delete, timeout: @timeout, url: url, headers: @headers)
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        parse err.response
      end
    end

    # def update_workspace(workspace_name, payload)
    #   url = "#{@api_url}/workspaces/#{workspace_name}"
    #   parse RestClient.patch(url, Oj.dump(payload), @headers)
    # end

    def get_workspace_info(workspace_name)
      url = "#{@api_url}/workspaces/#{workspace_name}"
      parse RestClient::Request.execute(method: :get, timeout: @timeout, url: url, headers: @headers)
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        parse err.response
      end
    end

    def refresh_credentials(workspace_name)
      url = "#{@api_url}/workspaces/#{workspace_name}/credentials"
      payload = {}
      parse RestClient::Request.execute(method: :put, timeout: @timeout, url: url, payload: payload, headers: @credentials)
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        parse err.response
      end
    end

    def deploy(workspace_name:, package:)
      url = "#{@api_url}/workspaces/#{workspace_name}/deploy"
      payload = {package: File.new(package, 'rb')}
      parse RestClient::Request.execute(method: :post, timeout: @timeout, url: url, payload: payload, headers: @credentials)
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        parse err.response
      end
    end

    def delete_from_workspace(function_name:, workspace_name:)
      url = "#{@api_url}/workspaces/#{workspace_name}/functions/#{function_name}"
      parse RestClient::Request.execute(method: :delete, timeout: @timeout, url: url, headers: @headers)
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        parse err.response
      end
    end

    # def list_workspace_functions(workspace_name)
    #   url = "#{@api_url}/workspaces/#{workspace_name}/functions"
    #   parse RestClient.get(url, @headers){|response, request, result| response }
    # end

    def run(function_name:, workspace_name:, payload:, method:, headers: {}, time: false, query: nil)
      url = "#{FaaStRuby.api_host}/#{workspace_name}/#{function_name}#{query}"
      headers['Benchmark'] = true if time
      if method == 'get'
        RestClient::Request.execute(method: :get, timeout: @timeout, url: url, headers: headers)
      else
        RestClient::Request.execute(method: method.to_sym, timeout: @timeout, url: url, payload: payload, headers: headers)
      end
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        return err.response
      end
    end

    def update_function_context(function_name:, workspace_name:, payload:)
      # payload is a string
      url = "#{@api_url}/workspaces/#{workspace_name}/functions/#{function_name}"
      parse RestClient::Request.execute(method: :patch, timeout: @timeout, url: url, payload: Oj.dump(payload), headers: @headers)
      # parse RestClient.patch(url, Oj.dump(payload), @headers){|response, request, result| response }
    rescue RestClient::ExceptionWithResponse => err
      case err.http_code
      when 301, 302, 307
        err.response.follow_redirection
      else
        parse err.response
      end
    end

    def parse(response)
      begin
        body = Oj.load(response.body) unless [500, 408].include?(response.code)
      rescue Oj::ParseError => e
        puts response.body
        raise e
      end
      case response.code
      when 401 then return error(["(401) Unauthorized - #{body['error']}"], 401)
      when 404 then return error(["(404) Not Found - #{body['error']}"], 404)
      when 409 then return error(["(409) Conflict - #{body['error']}"], 409)
      when 500 then return error(["(500) Error"], 500)
      when 408 then return error(["(408) Request Timeout"], 408)
      when 402 then return error(["(402) Limit Exceeded - #{body['error']}"], 402)
      when 422
        errors = ["(422) Unprocessable Entity"]
        errors << body['error'] if body['error']
        errors += body['errors'] if body['errors']
        return error(errors, 422)
      else
        return @struct.new(response, body, (body['errors'] || []), response.code)
      end
    end

    def error(errors, code)
      @struct.new(nil, nil, errors, code)
    end
  end
end
