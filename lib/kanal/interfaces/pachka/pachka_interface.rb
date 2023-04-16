# frozen_string_literal: true

require "faraday"
require "json"
require "logger"
require "kanal/core/interfaces/interface"
require "kanal/plugins/batteries/batteries_plugin"
require_relative "./helpers/local_server"
require_relative "./helpers/pachka_api"
require_relative "./plugins/pachka_integration_plugin"

module Kanal
  module Interfaces
    module Pachka
      #
      # Interface for Pachka messenger, to work with bots provided in the integration section of Pachka
      # messenger. It starts web server and accepts requests on api endpoint and sends requests to the
      # Pachka api for bot to actually respond.
      # Input parameters registered:
      #   input.pachka_command - command sent from users to bot. Full text of command passed, like "/hello"
      #
      # Output parameters registered:
      #   output.pachka_text - you can specify it in the respond block for bot to reply with text
      #   output.pachka_file_path - you can specify it in the respond block for bot to reply with file
      #
      class PachkaInterface < Kanal::Core::Interfaces::Interface
        include Kanal::Logger
        #
        # Creates interface with core and optional parameters
        # Be aware, it starts web server to accept Pachkas bot outgoing webhook requests
        #
        # @param core [Kanal::Core::Core] Kanal core
        # @param api_token [String] access_token you obtained in Pachka integrations for bot
        # @param host [String] host of web server accepting outgoing webhook requests from pachka bot
        # @param port [Integer] port of web server accepting outgoing webhook requests from pachka bot
        # @param local_server_debug_log [Boolean] pass true for local server to log requests to it to Kanal logger
        # @param api_debug_log [Boolean] pass true to log pachka api requests to STDOUT
        #
        def initialize(core, access_token, host: "localhost", port: 8090, local_server_log: false, api_debug_log: false)
          super(core)

          @port = port
          @host = host

          @local_server_log = local_server_log

          @api = Kanal::Interfaces::Pachka::Helpers::PachkaApi.new access_token, verbose: api_debug_log

          @access_token = access_token

          core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new
          core.register_plugin Kanal::Interfaces::Pachka::Plugins::PachkaIntegrationPlugin.new
        end

        def consume_output(output)
          text = output.pachka_text

          uploaded_files = []

          unless output.pachka_file_path.nil?
            uploaded_file = @api.upload_file output.pachka_file_path

            uploaded_files << uploaded_file
          end

          # When sending files without text
          text ||= " "

          @api.send_message(
            output.pachka_entity_id,
            output.pachka_entity_type,
            text,
            uploaded_files
          )
        rescue Exception => e
          logger.error "Error sending output as message to Pachka api! More info: #{e.full_message}"

          begin
            @api.send_message(
              output.pachka_entity_id,
              output.pachka_entity_type,
              "Error occured while sending message to Pachka api. Please consult with developers of this bot"
            )
          rescue Exception => e
            logger.fatal "Can't even send message about erro to Pachka api! More info: #{e.full_message}"
          end
        end

        def start
          logger.info "Starting Pachka interface on http://#{@host}:#{@port}"

          endpoint = Kanal::Interfaces::Pachka::Helpers::LocalServer.new(@host, @port)
          endpoint.on_request do |body|
            logger.debug "Local server received request with body: #{body}" if @local_server_log

            input = core.create_input
            input.source = :pachka
            input.pachka_entity_type = body["entity_type"]
            input.pachka_entity_id = body["entity_id"]
            input.pachka_query = body["content"]

            consume_input input
          end
          endpoint.start_accepting_requests
        end
      end
    end
  end
end
