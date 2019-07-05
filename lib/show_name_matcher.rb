module ShowNameMatcher
  def self.near_match?(s1,s2)
    # strip accents and normalize whitespace
    a1 = ActiveSupport::Inflector.transliterate(s1.to_s).strip.downcase.gsub(/\s+/,' ')
    a2 = ActiveSupport::Inflector.transliterate(s2.to_s).strip.downcase.gsub(/\s+/,' ')
    # remove possible surrounding quotes and all quote marks
    a1.gsub!(/["']/, '')
    a2.gsub!(/["']/, '')
    return true if a1.blank? || a2.blank?
    # canonicalize trailing 'A', 'An', 'The' to beginning
    if a1 =~ /^(.*),\s*(a|an|the)$/ then a1 = "#{$2} #{$1}" end
    if a2 =~ /^(.*),\s*(a|an|the)$/ then a2 = "#{$2} #{$1}" end
    a1 == a2
  end
end
