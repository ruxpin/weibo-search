#encoding: utf-8
require 'inifile'
require 'rchardet19'
require 'watir'
require 'digest/md5'
require 'nokogiri'
require 'logger'
require "sqlite3"

class Weibo

  attr_accessor :feeds, :new_feeds_insert_sql
  attr_reader :logger

  def initialize(options={})
    @feeds, @new_feeds_insert_sql = [], []
    setup_logger_by options
  end

  def self.set_options
    encoding = CharDet.detect(File.open("options.ini", &:readline)).encoding
    @options = IniFile.load("options.ini", :encoding => encoding)[name.downcase]
    @options.each do |key, value|
      instance_variable_set("@"+key, value)
      define_singleton_method(key.to_sym) {instance_variable_get("@"+key)}
    end
  end

  def setup_logger_by(options)
    @logger = Logger.new(STDOUT)
    @logger::level = options[:debug] ? Logger::DEBUG : Logger::INFO
    @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    @logger.formatter = proc { |severity, datetime, progname, msg| "#{datetime}: #{msg}\n" }
  end

  def browser
    @browser ||= Watir::Browser.new
  end

  def search_page(page_num)
    self.class.search_url_base+(self.class.keyword_param.strip.empty? ? '' : (self.class.keyword_param+'='))+"test"+"&"+self.class.page_param+'='+page_num.to_s
  end


private

# 每个微博的登录界面不一样，需要在具体类里实现填写用户密码并点击登录的行为并通过block传递进来
  def login(&block)
    begin
      logger.debug "login processing"
      logger.debug "Username: " + self.class.username
      logger.debug "password: " + self.class.password
      browser.goto self.class.login_url
      yield
      browser.visible = false unless logger.debug? 
      logger.info "用户成功登录！"
    rescue Watir::Exception::UnknownObjectException, Watir::Exception::UnknownFrameException => e
      logger.debug e
      logger.info "用户已登录！"
    end
  end

# 每个微博的信息截取方式不一样，需要在具体类里实现并通过block传递进来，同时block里应设置有搜索已至最后一页的边界条件
  def get_feeds_from_page(page=1, &block)
    logger.info "正在取回第"+page.to_s+"页搜索结果"
    browser.goto search_page(page)
    return_html=Nokogiri.HTML(browser.html, nil, 'UTF-8')
    yield(return_html)
    if page == self.class.max_page.to_i
      save_new_feeds_to_db
      return
    end
    sleep self.class.interval.to_i+rand(4)
    get_feeds_from_page page.next, &block
  end

  def save_feed(feed, feedlink)
    logger.debug "取回微博内容 ==> "+feed.text.gsub(/\s+/, "").gsub("\n",'')
    logger.debug "取回微博链接 ==> "+feedlink
    feeds << {:content => feed.text.gsub(/\s+/, "").gsub("\n",''), :link => feedlink}
  end

# 保存至数据库时都是只保留content的md5和link的md5
  def save_new_feeds_to_db
    @browser = browser.close unless logger::level == Logger::DEBUG # this will set @browser to nil so you can get a new Watir::Browser when you call browser
    logger.info "没有更多搜索结果，正在检查新微博并保存至数据库"
    logger.info "共取回微博信息"+feeds.length.to_s+"条"
    begin
      db = SQLite3::Database.open "feedsHub.db"
      feeds.each do |feed|
        content_md5=Digest::MD5.hexdigest(feed[:content])
        link_md5=Digest::MD5.hexdigest(feed[:link])
        rs = db.execute "select * from #{self.class.table} where content_md5=\'#{content_md5}\' and link_md5=\'#{link_md5}\'"
        logger.debug "select * from #{self.class.table} where content_md5=\'#{content_md5}\' and link_md5=\'#{link_md5}\'"
        if rs.empty?
          new_feeds_insert_sql << "insert into  #{self.class.table}(content_md5,link_md5) values(\'#{content_md5}\',\'#{link_md5}\')"
        end
      end
      if !new_feeds_insert_sql.empty?
        logger.info "在 <"+self.class.name+"> 的搜索有相关的新内容"+new_feeds_insert_sql.length.to_s+"条  \n\n"
      else
        logger.info "没有在 <"+self.class.name+"> 上搜索的新内容 \n\n"
      end
      db.execute "begin"
      new_feeds_insert_sql.each do |insert_sql|
        logger.debug "run sql: #{insert_sql}" if logger.debug?
        db.execute insert_sql
      end
      db.execute "commit"
    rescue SQLite3::Exception => e
      logger.info e
      exit
    ensure
      db.close if db
    end      
  end

end