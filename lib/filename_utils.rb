module FilenameUtils
  def filename_from_dates(base,from,to,ext='')
    [base, from.to_formatted_s(:filename), to.to_formatted_s(:filename)].join('-') <<
      ".#{ext}"
  end
  def filename_from_date(base,date,ext='')
    ext = ".#{ext}" unless ext.blank?
    "#{base}-#{date.to_formatted_s(:filename)}#{ext}"
  end
  def filename_from_object(obj, ext='')
    ext = ".#{ext}" unless ext.blank?
    "#{obj.class.to_s.downcase}-#{Time.current.to_formatted_s(:filename)}#{ext}"
  end
end
