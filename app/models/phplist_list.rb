class PhplistList < ActiveRecord::Base

  set_table_name "phplist_list"
  establish_connection :phplist

  validates_uniqueness_of :name

