# makes it easier to check for empty arrays when submitted from forms
class NilClass
  def empty? ; true ; end
end

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

  def boldify(s, tag=:strong, tag_opts = {})
    tag_opts_str = tag_opts.each_pair { |k,v| "#{k}=\"#{v}\"" }.join " "
    tagstart,tagend = "<#{tag.to_s} #{tag_opts_str}>", "</#{tag.to_s}>"
    self.gsub s, "#{tagstart}#{s}#{tagend}"
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
    # default: capitalize first letter AND any letter after a hyphen
    return self.gsub(/^(\w)|-(\w)/) { |a| a.upcase }
    #self.match(@@name_prefixes) ? self.sub(@@name_prefixes, "M#{$1}#{$2.capitalize}") :
    # self.capitalize
  end
  def name_capitalize
    self.split(/[\., ]+/).map { |w| w.capitalize_name_word }.join(" ")
  end
  def first_and_last_from_full_name
    names = self.split(/\s+/)
    last = names.pop.to_s
    last = "#{names.pop} #{last}" while @@name_connectors.include?(names.last)
    first = names.join(' ')
    return [first.strip,last.strip]
  end
end

# for safety, extend Object and NilClass etc with the capitalization helpers

class Object
  def name_capitalize ;  self.nil? ? "" : self.to_s ; end
end

class NilClass #:nodoc:
  def name_capitalize ; '' ; end
end
