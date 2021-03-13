class Label < ActiveRecord::Base

  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :name, :in => 1..20
  has_and_belongs_to_many :customers

  before_destroy :remove_from_join_table

  default_scope { order('name') }
  
  def remove_from_join_table
    ActiveRecord::Base.connection.execute("DELETE FROM customers_labels WHERE label_id=#{id}")
  end

  def self.all_labels
    Label.all
  end
end
