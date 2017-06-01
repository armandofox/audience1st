# MySQL 5.7 with Rails <4 requires this due to a breaking change in 5.7.3:
#  http://dev.mysql.com/doc/relnotes/mysql/5.7/en/news-5-7-3.html
# Fix on SO: http://stackoverflow.com/a/22314073/558723
if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter) # if using MySQL...
  class ActiveRecord::ConnectionAdapters::MysqlAdapter
    NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
  end
end

