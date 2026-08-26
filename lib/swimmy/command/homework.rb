module Swimmy
  module Command
    class Homework < Swimmy::Command::Base
      command "homework" do |client, data, match|
        title = match[:expression].to_s.strip

        if title.empty?
          client.say(channel: data.channel, text: "文書名を指定してください．\n使用方法: swimmy homework <文書名>")
          return
        end

        begin
          homeworks = Swimmy::Service::Homework.get_homeworks_by_title(title)

          if homeworks.empty?
            message = "文書『#{title}』中に宿題はありません．"
          else
            message = "文書『#{title}』中の宿題担当を表示します．\n以下のリンクからタスクを作成してください．\n"
            homeworks.each do |homework|
              message += homework.to_slack_link + "\n"
            end
          end

          client.say(channel: data.channel, text: message)
        rescue StandardError => e
          error_message = "ホームワーク情報の取得に失敗しました: #{e.message}"
          client.say(channel: data.channel, text: error_message)
        end
      end

      help do
        title "homework"
        desc "宿題の有無を表示します．"
        long_desc "homework\n" +
                  "会議の議事録に記載された宿題を表示します．"
      end
    end # class Homework
  end # module Command
end # module Swimmy

