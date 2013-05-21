# -*- coding: utf-8 -*-
require 'open-uri'
require 'nokogiri'

module Qubot::Plugin

  # Public: pixiv URL展開プラグイン
  #
  # pixivのURLに反応して詳細を発言します。
  #
  class Pixiv
    REGEXP = /https?:\/\/(www\.)?pixiv\.net\/member_illust\.php\?.*illust_id=(\d+)/i

    def self.register(bot)
      bot.hear(REGEXP) do |room, nick, msg, matches|
        id = matches[2]
        data = self.exec(id)
        if data[:error]
          bot.send(room, "Error: #{data[:error]}")
        else
          bot.send(room, data[:summary])
        end
      end
    end

    def self.exec(id)
      url = "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=#{id}"
      user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7'
      response = open(url, 'User-Agent' => user_agent).read()
      html = Nokogiri::HTML(response)
      title = html.css('title').text
      image_url = html.css('.img-container .medium-image img').first['src']
      tags = html.css('#tag_area div:first-child li a').map(&:text)
      summary = "[タイトル] #{title}\n"
      summary += "[タグ] #{tags.join(', ')}"

      {
        image_url: image_url,
        summary: summary,
      }
    rescue => e
      { error: e.inspect }
    end
  end

end
