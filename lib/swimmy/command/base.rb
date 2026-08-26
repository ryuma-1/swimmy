# Usage:
#
# class YourCommand < Swimmy::Command::Base
#   match /hey (.*)/ do |client, data, match|
#     ...
#     spreadsheet...
#   end
#
#   command "wow" do |client, data, match|
#     ...
#     spreadsheet...
#   end
#
#   on "hello" do |client, data|
#     ...
#   end
# end
#

require "slack-ruby-bot"

module Swimmy
  module Command
    class << self
      attr_accessor :spreadsheet, :mqtt_client
    end

    class Base < SlackRubyBot::Commands::Base

      # You can use spreadsheet object in your command
      def self.spreadsheet
        Swimmy::Command.spreadsheet
      end

      # You can use mqtt_client object in your command
      def self.mqtt_client
        Swimmy::Command.mqtt_client
      end

      # You can use rask-cli driver in your command
      # e.g. driver.task_list(username, is_json)
      def self.driver
        Swimmy::Service::RaskCliDriver
      end

      # Create help_message for your command.
      # You can use in your command, for example:
      #   command "lottery" do |client, data, match|
      #     unless match[:expression]
      #       client.say(channel: data.channel, text: help_message)
      #     else
      #       ...
      def self.help_message(command_name = nil)
        command_name ||= command_name_from_class
        hlp = SlackRubyBot::Commands::Support::Help.instance.find_command_help_attrs(command_name)
        "#{command_name} - #{hlp.command_desc}\n\n#{hlp.command_long_desc}" if hlp
      end

      # You can Create periodic task by using tick.
      #   tick |client, data| do
      #     CHANNEL_LIST.each do |channel|
      #       client.say(channel: channel, text: "Hi!")
      #     end
      #   end
      def self.tick(&block)
        on "ping", &block
      end

      def self.on(event_name, &block)
        @hooks ||= {}
        @hooks[event_name] ||= []
        @hooks[event_name] << block
      end

      def self.invoke(client, data)
        # data.type is one of
        # "ping" ... websocket layer event
        # "hello" ... Slack greeting event
        # "message", "reaction_added" etc.: Slack Event API event
        #
        event_name = data.type
        if @hooks && @hooks[event_name]
          @hooks[event_name].each do |hook|
            begin
              hook.call(client, data)
            rescue StandardError => e
              puts "Error in 'on' hook: #{e.message}"
            end
          end
        end
        super(client, data)
      end

      def self.child_command_classes(command_classes)
        command_classes.reject do |k|
          k.name&.starts_with?('SlackRubyBot::Commands::')
        end
      end
      private_class_method :child_command_classes

      def self.invoke_all(client, data)
        child_command_classes(SlackRubyBot::Commands::Base.command_classes).each do |command_class|
          command_class.invoke(client, data)
        end
      end
    end
  end
end
