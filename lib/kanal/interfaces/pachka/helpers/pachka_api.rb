# frozen_string_literal: true

require "json"
require "faraday"
require "faraday/multipart"
require "mini_mime"
require "kanal"

module Kanal
  module Interfaces
    module Pachka
      module Helpers
        #
        # Class to work with Pachka public api
        #
        class PachkaApi
          include Kanal::Logger

          UploadedFile = Struct.new(:file_key, :file_name, :file_type, :file_size)

          #
          # @param access_token [String] access token for bot
          # @param verbose [Boolean] pass true to enable STDOUT logging of requests and responses
          #
          def initialize(access_token, verbose: false)
            @access_token = access_token

            @conn = Faraday.new(
              url: "https://api.pachca.com/api/shared/v1",
              headers: { "Authorization" => "Bearer #{@access_token}" }
            ) do |faraday|
              if verbose
                logger = ::Logger.new $stdout
                logger.level = ::Logger::DEBUG
                faraday.response :logger, logger, body: true, bodies: { request: true, response: true }
              end

              faraday.request :multipart
            end
          end

          #
          # Method sends text message via bot into the Pachka api
          # with optionally sending files
          #
          # @param entity_id [Integer] id of discussion obtained from input
          # @param entity_type [String] type of chat obtained from input
          # @param text [String] text to be sent
          # @param uploaded_files [Array] array of UploadedFile objects to send with message
          #
          # @return [void] <description>
          #
          def send_message(entity_id, entity_type, text, uploaded_files = [])
            payload = {
              message: {
                entity_type: entity_type,
                entity_id: entity_id,
                content: text
              }
            }

            unless uploaded_files.empty?
              files = []

              uploaded_files.each do |uploaded_file|
                files << {
                  key: uploaded_file.file_key,
                  name: uploaded_file.file_name,
                  file_type: uploaded_file.file_type,
                  size: uploaded_file.file_size
                }
              end

              payload[:message][:files] = files
            end

            @conn.post(
              "messages",
              payload.to_json,
              { "Content-Type" => "application/json" }
            )
          rescue Exception => e
            logger.error "Cant send message to Pachka api! Error: #{e.full_message}"
            raise
          end

          #
          # Method uploads file at filepath to Pachka api and returns UploadedFile
          #
          # @param filepath [String] local filepath to file
          #
          # @return [UploadedFile] object containing all needed info to send with message
          #
          def upload_file(filepath)
            # Obtaining all the needed fields for uploading a file
            res = @conn.post("uploads")

            raise "Problem with requesting info about uploads! More in api logs." unless res.success?

            first_response_body = JSON.parse(res.body)

            direct_url = first_response_body["direct_url"]

            file_key = first_response_body["key"]

            filename = File.basename filepath

            file_key = file_key.sub "${filename}", filename

            mime_type = MiniMime.lookup_by_filename(filename).content_type

            # filepath = File.absolute_path(filepath) if File.absolute_path(filepath) != filepath

            file = Faraday::Multipart::FilePart.new filepath, mime_type

            req_params = first_response_body

            req_params.delete "direct_url"

            req_params["key"] = file_key

            payload = req_params
            payload[:file] = file

            res = @conn.post(direct_url, payload)

            raise "Problem with uploading file to Pachka api! More in api logs." unless res.success?

            UploadedFile.new(
              file_key,
              filename,
              mime_type.include?("image") ? "image" : "file",
              File.size(filepath)
            )
          rescue Exception => e
            logger.error "Error sending file to Pachka api! More info: #{e.full_message}"
          end
        end
      end
    end
  end
end
