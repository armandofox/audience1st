class Clock
  # an injected dependency that allows us to cleanly control what time it is for testing.
  def self.now ; Time.now ; end           # instead of Time.now
  def self.today ; self.now.to_date ; end # instead of Date.today
end
