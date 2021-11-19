class SeatingZone < ActiveRecord::Base

  default_scope { order(:display_order, :name) }

  HUMANIZED_ATTRIBUTES = {:name => 'Full name'}
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr] || super
  end

  validates :name, :presence => true, :uniqueness => true,
            :format => {:with => /\A[a-zA-Z0-9_]+\Z/, :message => 'can only include letters, digits, and underscores'}

  validates :short_name, :presence => true, :uniqueness => true, :length => {:maximum => 8},
            :format => {:with => /\A[A-Za-z0-9]+\z/, :message => 'can only include letters and digits'}

  validates :display_order, :presence => true,
            :numericality => { :greater_than_or_equal_to => 0, :only_integer => true } 
  
  has_many :vouchertypes

  def self.hash_by_short_name
    SeatingZone.all.map { |z| [z.short_name, z.name] }.to_h.freeze # zones["r"] => "Reserved"
  end

  # which seatmaps refer to this zone?

  def seatmaps
    Seatmap.all.select { |sm|  sm.references_zone?(self) }
  end

end

