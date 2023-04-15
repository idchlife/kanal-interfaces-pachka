# frozen_string_literal: true

require "webrick"
require "json"

module Kanal
  module Interfaces
    module Pachka
      module Helpers
        #
        # This class starts web server and accepts requests on api endpoint
        #
        class LocalServer
          #
          # @param host [String] host of web server (usually localhost)
          # @param port [Integer] port of web server
          #
          def initialize(host, port)
            @on_request_block = nil
            @host = host
            @port = port
          end

          #
          # Provide block to this method which will be called with has parameters from json body
          #
          # @param &block [Proc] block which will be called with Hash parsed from json body as first argument
          #
          # @return [void] <description>
          #
          def on_request(&block)
            @on_request_block = block
          end

          #
          # Method to start web server and accept requests.
          # Requests are accepted on @host:@port where @port is provided in constructor
          # Endpoint: /api/bod
          # Accepts only method POST and application/json Content-Type
          # After request accepted it"s body is parsed and passed to @on_request_block
          #
          # @return [void] <description>
          #
          def start_accepting_requests
            server = WEBrick::HTTPServer.new(Host: @host, Port: @port)

            server.mount_proc "/api/bot" do |req, res|
              if req.request_method == "POST" && req.content_type == "application/json"
                begin
                  body = JSON.parse(req.body)

                  @on_request_block&.call(body)
                rescue JSON::ParserError
                  res.status = 400
                  res.body = "Bad Request"
                end
              else
                res.status = 405
                res.body = "Method Not Allowed"
              end

              res["Content-Type"] = "text/plain"
              res["Content-Length"] = res.body.length
            end

            trap("INT") { server.shutdown }

            server.start
          end
        end
      end
    end
  end
end
