require 'active_support/time'
require 'date'
require 'json'
require 'net/https'
require 'uri'

module Swimmy
  module Service
    class GoogleCalendarGateway
      # 研究室の種類とそれに対するspreadsheetのインデックスの対応表
      CALENDAR_MAP = {
        GN:  1,
        New: 2
      }.freeze

      def initialize(calendar_type, sheet)
        unless CALENDAR_MAP.key?(calendar_type)
          raise ArgumentError, "Invalid calendar_type: #{calendar_type}"
        end
        unless sheet.is_a?(Sheetq::Service::Sheet)
          raise ArgumentError, "sheet must be a Sheetq::Service::Sheet object"
        end

        calendars = sheet.fetch
        sheet_index = CALENDAR_MAP[calendar_type]

        @google_oauth = Swimmy::Resource::GoogleOAuth.new(
          'config/credentials.json',
          'config/tokens.json'
          )

        @calendar = calendars[sheet_index]

        if @calendar.nil?
          raise "カレンダーが見つかりません: インデックス #{sheet_index}"
        end
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
    end # class GoogleCalendarGateway
  end # module Service
end # module Swimmy
