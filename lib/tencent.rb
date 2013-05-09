#encoding: utf-8
require_relative 'weibo'

class Tencent < Weibo

  set_options
  
  def process_pages
    login do
      browser.frame(:id, "login_div").text_field(:id, "u").set(Tencent.username)
      browser.frame(:id, "login_div").text_field(:id, "p").set(Tencent.password)
      puts "请在打开的页面输入验证码，输入完毕请在此按任意键继续"
      gets
      browser.frame(:id, "login_div").button(:id, "login_button").click
    end
    get_feeds_from_page do |return_html|
      content = return_html.xpath("//div[@class = 'msgBox']")
      content.each do |feed|
        next if feed.xpath("./div/span/a[@class = 'time']").empty?
        feedlink = feed.xpath("./div/span/a[@class = 'time']").last['href']
        feed = feed.xpath("./div[@class = 'msgCnt']")
        save_feed(feed, feedlink)
      end
      unless return_html.xpath("//a[@class = 'pageBtn']").last.content =~ /下一页/
        save_new_feeds_to_db
        return
      end
    end
  end

end