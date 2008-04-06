class String

  def self.random_string(len)
    # generate a random string of alphanumerics, but to avoid user confusion,
    # omit o/0 and 1/i/l
    newpass = ''
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("2".."9").to_a - %w[O o L l I i]
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def wrap(col = 80)
    # from blog.macromates.com/2006/wrapping-text-with-regular-expressions
    self.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/, "\\1\\3\n") 
  end

  def valid_email_address?
    return self && self.match( /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.([A-Z]{2,4})?$/i )
  end

  def default_to(val)
    self.blank? ? val : self.to_s
  end
  @@name_connectors = %w[and & van von der de di]
  @@name_prefixes = /^m(a?c)(\w+)/i
  def capitalize_name_word
    # short all-caps (like "OJ") are left as-is
    return self if self.match(/^[A-Z]+$/)
    # words that are already BiCapitalized are left as-is
    # (i.e., contain at least one uppercase letter that is preceded by
    # a lowercase letter; catches McHugh, diBlasio, etc.)
    return self if self.match( /[a-z][A-Z]/ )
    # single initial: capitalize the initial
    return "#{self.upcase}." if self.match(/^\w$/i)
    # connector word (von, van, de, etc.) - lowercase
    return self.downcase if @@name_connectors.include?(self.downcase)
    # default: capitalize first letter
    return self.sub(/^(\w)/) { |a| a.upcase }
    #self.match(@@name_prefixes) ? self.sub(@@name_prefixes, "M#{$1}#{$2.capitalize}") :
    # self.capitalize
  end
  def name_capitalize
    self.split(/[\., ]+/).map { |w| w.capitalize_name_word }.join(" ")
  end
end

