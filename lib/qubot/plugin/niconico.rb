# -*- coding: utf-8 -*-
require 'open-uri'
require 'nokogiri'

module Qubot::Plugin

  # Public: ニコニコ動画URL展開プラグイン
  #
  # ニコニコ動画のURLに反応して詳細を発言します。
  #
  class Niconico
    REGEXP = /https?:\/\/(www\.)?nicovideo\.jp\/watch\/(.+)/i

    def self.register(bot)
      bot.hear(REGEXP) do |room, nick, msg, matches|
        id = matches[2]
        data = self.exec(id)
        if data[:error]
          bot.send(room, "Error: #{data[:error]}")
        else
          bot.send(room, data[:thumbnail_url])
          bot.send(room, data[:summary])
        end
      end
    end

    def self.exec(id)
      url = "http://ext.nicovideo.jp/api/getthumbinfo/#{id}"
      response = open(url).read()
      xml = Nokogiri::XML(response)
      thumb_data = self.build_thumb_data(xml)
      {
        thumbnail_url: thumb_data[:thumbnail_url],
        summary: self.build_summary(thumb_data),
      }
    rescue => e
      { error: e.inspect }
    end

    def self.build_summary(thumb)
      summary = []
      summary << "[タイトル] #{thumb[:title]} (#{thumb[:length]})"
      summary << "[再生] #{thumb[:view_counter]} [コメント] #{thumb[:comment_num]} [マイリスト] #{thumb[:mylist_counter]}"
      summary << "[タグ] #{thumb[:tags].join(", ")}"
      summary << "[説明] #{thumb[:description]}"

      summary.join("\n")
    end

    def self.build_thumb_data(xml)
      {
        title: xml.xpath('//thumb/title').text,
        description: xml.xpath('//thumb/description').text[0, 80],
        thumbnail_url: xml.xpath('//thumb/thumbnail_url').text + '&format=jpg',
        length: xml.xpath('//thumb/length').text,
        view_counter: self.number_format(xml.xpath('//thumb/view_counter').text),
        comment_num: self.number_format(xml.xpath('//thumb/comment_num').text),
        mylist_counter: self.number_format(xml.xpath('//thumb/mylist_counter').text),
        tags: self.parse_tags(xml.xpath('//thumb/tags')),
      }
    end

    def self.number_format(num)
      num.to_s.reverse.gsub(/(\d{3})(?=\d)/,'\1,').reverse
    end

    def self.parse_tags(tag_elements)
      tags = []

      jp_tag_elements = tag_elements.select do |element|
        element['domain'] && element['domain'] == 'jp'
      end
      return tags if jp_tag_elements.size == 0

      jp_tags = jp_tag_elements.first.children

      jp_tags.each do |element|
        value = element.text.strip
        next if value.empty?
        tags << value
      end

      tags
    end
  end

end
