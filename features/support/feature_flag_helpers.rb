module FeatureFlagHelpers
  def enable_new_feature(feature_name)
    Option.enable_feature!(feature_name)
  end

  def disable_new_feature(feature_name)
    Option.disable_feature!(feature_name)
  end
end

World(FeatureFlagHelpers)