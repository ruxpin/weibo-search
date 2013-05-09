#encoding: utf-8
require_relative 'weibo'

class Sina < Weibo
  
  set_options

  def process_pages
    login do
      browser.text_field(:name, "username").set(Sina.username)
      browser.text_field(:name, "password").set(Sina.password)
      browser.a(:class, "W_btn_g").click
    end
    get_feeds_from_page do |return_html|
      if return_html.xpath("//ul[@class = 'search_page_M']").empty?
        save_new_feeds_to_db
        return
      end
      content = return_html.xpath("//dd[@class = 'content']")
      content.each do |feed|
        feedlink = feed.xpath("./p/a[@class = 'date']").last['href']
        feed = feed.xpath("./p[@node-type = 'feed_list_content']")
        save_feed(feed, feedlink)
      end
    end
  end

end