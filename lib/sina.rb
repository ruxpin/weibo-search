#encoding: utf-8
require_relative 'weibo'

class Sina < Weibo
  
  set_options_for name.downcase

  def initialize(options={})
    super
  end

  def process_pages
    login do
      browser.text_field(:name, "username").set(Sina.username)
      browser.text_field(:name, "password").set(Sina.password)
      browser.a(:class, "W_btn_g").click
    end
    get_feeds_from_page do |return_html|
      if return_html.xpath("//ul[@class = 'search_page_M']").empty?
        logger.info "没有更多搜索结果"
        save_new_feeds_to_db
        return
      end
      content = return_html.xpath("//dd[@class = 'content']")
      content.each do |feed|
        feedlink = feed.xpath("./p/a[@class = 'date']").last['href']
        logger.debug "取回微博内容 ==> "+feed.content
        logger.debug "取回微博链接 ==> "+feedlink
        feeds << {:content => feed.content, :link => feedlink}
      end
    end
    browser.close
    logger.info "共取回微博信息"+feeds.length.to_s+"条"
  end

end