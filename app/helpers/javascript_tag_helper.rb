module JavascriptTagHelper
  ## Load jQuery, rails.js, and everything in the Javascript dir.
  ## Obsoleted by asset pipeline in Rails 3
  
  def javascript_include_tags_for_jquery(*args)
    default_files = %w(jquery.min rails)
    other_files = Dir["#{ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR}/*.js"].
      map { |s| File.basename(s).gsub(/\.js$/,'') }.
      delete_if { |s| default_files.include? s }
    javascript_include_tag(*default_files) +
      javascript_include_tag(other_files)
  end
end
