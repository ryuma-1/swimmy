module Swimmy
  module Command
    class MinutesUploader < Swimmy::Command::Base
      command "minutes_uploader" do |client, data, match|

        # 1. Google OAuth の認証（失敗したらその時点で終了）
        google_oauth = 
        begin
          Swimmy::Resource::GoogleOAuth.new('config/credentials.json', 'config/tokens.json')
        rescue => e
          puts "OAuth Error: #{e.message}" # デバッグ用にログ出力
          client.say(channel: data.channel, text: "Google OAuthの認証に失敗しました．設定を確認してください．")
          next # commandブロックを抜ける
        end

        client.say(channel: data.channel, text: "OAuth認証成功") # デバッグ用にログ出力

        # 2. 予定の取得処理
        begin
          sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)
          calendars = sheet.fetch
          calenders_num = calendars.size

          ＃ デバッグ用にログ出力
          client.say(channel: data.channel, text: "予定の取得に成功しました．#{calenders_num}件の予定が見つかりました．") # デバッグ用にログ出力
          calendars.each do |calendar|
            client.say(channel: data.channel, text: "Calendar: #{calendar.name} (ID: #{calendar.id})")


          end
        end

      end
    end #class Coop    
  end #module Command
end #module Swimmy
