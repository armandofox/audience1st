class SeatingZone < ActiveRecord::Base

  validates :name, :presence => true, :uniqueness => true
  validates :short_name, :presence => true, :uniqueness => true

  has_many :vouchertypes

end

