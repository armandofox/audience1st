class Label < ActiveRecord::Base

  validates_uniqueness_of :name
  validates_length_of :name, :in => 1..20
  has_and_belongs_to_many :customers

  def self.all_labels
    Label.find(:all)
  end
end
