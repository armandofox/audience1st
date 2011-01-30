module FilenameUtils
  def filename_from_dates(base,from,to,ext='')
    [base, from.to_formatted_s(:filename), to.to_formatted_s(:filename)].join('-') <<
      ".#{ext}"
  end
  def filename_from_date(base,date,ext='')
    "#{base}-#{date.to_formatted_s(:filename)}.#{ext}"
  end
  def filename_from_object(obj, ext='')
    "#{obj.class.to_s.downcase}-#{Time.now.to_formatted_s(:filename)}.#{ext}"
  end
end
