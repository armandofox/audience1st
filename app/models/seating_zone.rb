class SeatingZone < ActiveRecord::Base

  default_scope { order(:display_order, :name) }

  validates :name, :presence => true, :uniqueness => true,
            :format => {:with => /\A[a-zA-Z0-9_]+\Z/, :message => 'can only include letters, digits, and underscores'}

  validates :short_name, :presence => true, :uniqueness => true, :length => {:maximum => 8},
            :format => {:with => /\A[A-Za-z0-9]+\z/, :message => 'can only include letters and digits'}

  has_many :vouchertypes

  def self.hash_by_short_name
    SeatingZone.all.map { |z| [z.short_name, z.name] }.to_h.freeze # zones["r"] => "Reserved"
  end

  # which seatmaps refer to this zone?

  def seatmaps
    Seatmap.all.select { |sm|  sm.references_zone?(self) }
  end

end

