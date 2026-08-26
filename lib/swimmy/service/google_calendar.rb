require 'active_support/time'
require 'date'
require 'json'
require 'net/https'
require 'uri'

module Swimmy
  module Service
    class GoogleCalendar

      def initialize(calendar)
        if calendar.nil?
          raise ArgumentError, "calendar cannot be nil"
        end
        unless calendar.is_a?(Swimmy::Resource::Calendar)
          raise ArgumentError, "calendar must be a Swimmy::Resource::Calendar object"
        end

        @calendar = calendar

        @google_oauth = Swimmy::Resource::GoogleOAuth.new(
          'config/credentials.json',
          'config/tokens.json'
          )
      end

      def date_to_events(target_date)
        date = target_date.is_a?(String) ? Date.parse(target_date) : target_date

        json_str = fetch_json_events(@calendar.id, date)
        json_to_event(json_str)
      end

      private

      def fetch_json_events(calendar_id, date)
        uri = URI.parse("https://www.googleapis.com/calendar/v3/calendars/#{calendar_id}/events")

        uri.query = URI.encode_www_form({
          singleEvents: true,
          timeMin: date.to_datetime.beginning_of_day.rfc3339,
          timeMax: date.to_datetime.end_of_day.rfc3339,
        })

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Get.new(uri.request_uri)
        req['Accept'] = 'application/json'
        req['Authorization'] = "Bearer #{@google_oauth.token}"

        res = http.request(req)
        raise "Google Calendar API Error: #{res.code} #{res.body}" unless res.code == "200"

        res.body
      end

      def json_to_event(json_str)
        json_parsed = JSON.parse(json_str)
        items = json_parsed.dig('items') || []

        items.map do |event|
          start_time_raw = event.dig('start', 'dateTime') || event.dig('start', 'date')
          start_time = DateTime.parse(start_time_raw).strftime('%H:%M:%S')
          summary = event['summary']

          Swimmy::Resource::Event.new(start_time, summary, @calendar.name)
        end
      end

    end # class GoogleCalendar
  end # module Service
end # module Swimmy
