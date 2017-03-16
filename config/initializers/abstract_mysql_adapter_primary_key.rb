# This can be removed for Rails >=3 rails3

class ActiveRecord::ConnectionAdapters::MysqlAdapter  
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end
