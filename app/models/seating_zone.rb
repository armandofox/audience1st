class SeatingZone < ActiveRecord::Base

  default_scope { order(:display_order) }

  validates :name, :presence => true, :uniqueness => true,
            :format => {:with => /\A[a-z0-9_]+\Z/i, :message => 'only letters, numbers, and underscores allowed'}

  validates :short_name, :presence => true, :uniqueness => true, :length => {:maximum => 8},
            :format => {:with => /\A[A-Za-z0-9]+\z/, :message => 'only letters and digits allowed'}

  has_many :vouchertypes

  def self.hash_by_short_name
    SeatingZone.all.map { |z| [z.short_name, z.name] }.to_h.freeze # zones["r"] => "Reserved"
  end

end

