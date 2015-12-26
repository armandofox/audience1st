class Label < ActiveRecord::Base

  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :name, :in => 1..20
  has_and_belongs_to_many :customers

  before_destroy :remove_from_join_table

  attr_accessible :name

  def remove_from_join_table
    connection.execute("DELETE FROM customers_labels WHERE label_id=#{id}")
  end

  def self.rename_customer(old_id, new_id)
    connection.update("UPDATE customers_labels SET customer_id='#{new_id}' WHERE customer_id='#{old_id}'", "CustomersLabels Update")
  end

  def self.all_labels
    Label.find(:all)
  end
end
