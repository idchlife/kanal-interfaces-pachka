# frozen_string_literal: true

require "kanal"
require "kanal/core/plugins/plugin"

module Kanal
  module Interfaces
    module Pachka
      module Plugins
        #
        # Pachka integration plugin for parameters and conditions and hooks registration
        #
        class PachkaIntegrationPlugin < Kanal::Core::Plugins::Plugin
          include Kanal::Logger

          def name
            :pachka_integration
          end
          #
          # @param core [Kanal::Core::Core] <description>
          #
          # @return [void] <description>
          #
          def setup(core)
            register_input_parameters core
            register_output_parameters core
            register_conditions core
            register_hooks core
          end

          def register_input_parameters(core)
            core.register_input_parameter :pachka_query, readonly: true
            core.register_input_parameter :pachka_entity_id, readonly: true
            core.register_input_parameter :pachka_command, readonly: true
            core.register_input_parameter :pachka_text, readonly: true
          end

          def register_output_parameters(core)
            core.register_output_parameter :pachka_entity_id
            core.register_output_parameter :pachka_text
            core.register_output_parameter :pachka_file_path
          end

          def register_hooks(core)
            core.hooks.attach :input_before_router do |input|
              input.pachka_command = input.pachka_query.split.first[1..] # "/hello" transforms to "hello"
              input.pachka_text = input.pachka_query.split[1..].join " " # removes command and leaves just message
            rescue e
              logger.error "Error parsing input.pachka_query to populate input.pachka_command and input.pachka_text! Query: #{input.pachka_query} More info: #{e.full_message}"
              input.pachka_command = "ERROR" if input.pachka_command.nil?
              input.pachka_text = "ERROR" if input.pachka_text.nil?
            end

            core.hooks.attach :output_before_returned do |input, output|
              output.pachka_entity_id = input.pachka_entity_id
            end
          end

          def register_conditions(core)
            core.add_condition_pack :pachka do
              add_condition :query do
                with_argument

                met? do |input, _core, argument|
                  input.pachka_query == argument
                end
              end

              add_condition :command do
                with_argument

                met? do |input, _core, argument|
                  input.pachka_command.to_sym == argument || input.pachka_command == argument
                end
              end

              add_condition :text do
                with_argument

                met? do |input, _core, argument|
                  input.pachka_text == argument
                end
              end
            end
          end
        end
      end
    end
  end
end
