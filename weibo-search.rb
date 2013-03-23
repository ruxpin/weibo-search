#encoding: utf-8
require 'optparse'
require_relative 'lib/sina'

options = {}
begin
  option_parser = OptionParser.new do |opts|
    # 命令行工具的帮助信息
    opts.banner = "   微博搜索信息更新工具，Created By Rux\n"

    # Option 为initdb，不带argument，用于将switch默认设置成true或false
    
    # 第一项是Short option（没有可以直接在引号间留空），第二项是Long option，第三项是对Option的描述
    options[:create_db] = false
    opts.on('-c', '--create_db', "创建程序数据库，如要初始化数据库请用-i参数\n") do
      options[:create_db] = true
    end

    options[:debug] = false
    opts.on('-d', '--debug', "在debug模式下运行\n") do
      options[:debug] = true
    end
    # Option 为name，带argument，用于将argument作为数值解析，留待备用
    options[:init_table] = false
    opts.on('-i NAME', '--init_table Name', '输入表名') do |value|
      options[:table_name] = value
      options[:init_table] = true
    end

    # Option 作为flag，带一组用逗号分割的arguments，用于将arguments作为数组解析，留待备用
    # opts.on('-a A,B', '--array A,B', Array, 'List of arguments') do |value|
    #   options[:array] = value
    # end
  end.parse!
rescue OptionParser::InvalidOption => e
  puts e
  exit 1
end

if options[:create_db]
  begin
    db=SQLite3::Database.new "feedsHub.db"
    puts "\n数据库创建完毕\n如已有数据库及数据，将不执行任何操作"
    rescue SQLite3::Exception => e
      puts "Exception occured"
      puts e
    ensure
      db.close if db
      exit unless options[:init_db]
  end
end

if options[:init_table]
  begin
    db=SQLite3::Database.open "feedsHub.db"
    db.execute "drop table if exists #{options[:table_name]}"
    db.execute "create table if not exists #{options[:table_name]}(id INTEGER PRIMARY KEY autoincrement, content_md5 text, link_md5 text)"
    puts "\n数据库初始化完毕"
    rescue SQLite3::Exception => e
      puts "Exception occured"
      puts e
    ensure
      db.close if db
      exit
  end
end

s=Sina.new options
s.process_pages