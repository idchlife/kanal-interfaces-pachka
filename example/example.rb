# frozen_string_literal: true

require "logger"
require "kanal"
require "kanal/interfaces/pachka"

core = Kanal::Core::Core.new
logger = Logger.new $stdout
logger.level = Logger::WARN
core.add_logger logger

api_key = ENV.fetch("PACHKA_ACCESS_TOKEN", nil)

puts "Pachka api key: #{api_key}"

interface = Kanal::Interfaces::Pachka::PachkaInterface.new(core, api_key, local_server_log: true, api_debug_log: true)

interface.router.default_response do
  pachka_text "Hey! I don't know how to answer to this yet... But I will, someday ;)"
end

interface.router.error_response do
  pachka_text "Something went wrong. We're already fixing!"
end

interface.router.configure do
  on :pachka, command: :ping do
    respond do
      pachka_text "pong!"
    end
  end

  on :pachka, command: :meme do
    respond do
      pachka_text "Here is meme about: #{input.pachka_text}"
    end
  end

  on :pachka, command: :sample_image do
    respond do
      pachka_file_path "./sample_image.png"
    end
  end

  on :pachka, command: :sample_file do
    respond do
      pachka_text "Text provided with file"
      pachka_file_path "./sample_file.zip"
    end
  end
end

puts "Starting interface!"
interface.start
