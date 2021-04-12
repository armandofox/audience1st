module FeatureFlagHelpers
	#fix indents, two spaces, this is standard
	#maybe don't call it toggle
	def enable_toggle(feature_name)
		Option.enable_feature!(feature_name)
	end

	#def disable...
end

World(FeatureFlagHelpers)