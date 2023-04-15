# frozen_string_literal: true

require "kanal"
require "kanal/plugins/batteries/batteries_plugin"

RSpec.describe Kanal::Interfaces::Pachka do
  it "plugin registered successfully" do
    core = Kanal::Core::Core.new

    plugin = Kanal::Interfaces::Pachka::Plugins::PachkaIntegrationPlugin.new

    expect { core.register_plugin plugin }.not_to raise_error
  end

  it "plugin parses pachka_query and converts to pachka_command, pachka_text" do
    core = Kanal::Core::Core.new

    plugin = Kanal::Interfaces::Pachka::Plugins::PachkaIntegrationPlugin.new

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new
    core.register_plugin plugin

    core.router.default_response do
      pachka_text "Default response"
    end

    output = nil

    core.router.configure do
      on :flow, :any do
        respond do
          pachka_text "Something"
        end
      end
    end

    core.router.output_ready do |o|
      output = o
    end

    input = core.create_input
    input.pachka_query = "/hello this is dog"

    input_params_check = lambda do |input|
      expect(input.pachka_command).to eq "hello"
      expect(input.pachka_text).to eq "this is dog"
    end

    core.hooks.attach :input_before_router do |input|
      input_params_check.call input
    end

    core.router.consume_input input
  end
end
