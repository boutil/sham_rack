require "patron"
require "sham_rack/registry"
require "uri"

module Patron

  class Session

    alias :handle_request_without_sham_rack :handle_request

    def handle_request(patron_request)
      uri = URI.parse(patron_request.url)
      rack_app = ShamRack.application_for(uri.host, uri.port)
      if rack_app
        handle_request_with_rack(patron_request, rack_app)
      else
        handle_request_without_sham_rack(patron_request)
      end
    end

    private

    def handle_request_with_rack(patron_request, rack_app)
      env = rack_env_for(patron_request)
      rack_response = rack_app.call(env)
      patron_response(rack_response)
    end

    def rack_env_for(patron_request)
      Rack::MockRequest.env_for(patron_request.url, :method => patron_request.action)
    end

    def patron_response(rack_response)
      status, headers, body = rack_response
      res = Patron::Response.new
      res.instance_variable_set(:@status, status)
      res.instance_variable_set(:@body, assemble_body(body))
      # res.instance_variable_set(:@status_line, webmock_response.status[1])
      # res.instance_variable_set(:@headers, webmock_response.headers)
      res
    end

    def assemble_body(body)
      content = ""
      body.each { |fragment| content << fragment }
      content
    end

  end

end