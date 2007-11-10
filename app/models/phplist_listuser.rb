class PhplistListuser < ActiveRecord::Base

  set_table_name "phplist_listuser"
  establish_connection :phplist
