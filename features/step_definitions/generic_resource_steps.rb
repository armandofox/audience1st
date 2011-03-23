Given /^the following (.*)s exist:/ do |thing, instances|
  klass = thing.gsub(/\s+/, '_').classify.constantize
  instances.hashes.each do |hash|
    hash.each_pair do |k,v|
      if v =~ /^(\S+):(.*)$/
        hash["#{k}_id"] = k.classify.constantize.send("find_by_#{$1}!", $2)
        hash.delete(k)
      end
    end
    klass.send(:create!, hash)
  end
end
