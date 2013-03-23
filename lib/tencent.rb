#encoding: utf-8
require_relative 'weibo'

class Tencent < Weibo

  set_options_for name.downcase

  def initialize()
  end

  def process_pages
    login do
      browser.text_field(:id, "u").set(Tencent.username)
      browser.text_field(:id, "p").set(Tencent.password)
      browser.form(:id, "loginform").submit
    end
    # browser.goto search_url_page(1)
    # @result_html=Nokogiri.HTML(browser.html)
    # content = @result_html.xpath("//dd[@class = 'content']")
    # content.each do |link|
    #   puts link.content
    #   datelink = link.xpath("./p/a[@class = 'date']").last
    #   puts datelink.content
    #   puts datelink['href']
    #   puts "---------------------------------------------"
    # end
    # browser.close
  end

end