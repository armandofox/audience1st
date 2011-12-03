class TbaDownload < BulkDownload

  private

  BASE_URL = 'http://tix.theatrebayarea.org/ticketing/'
  REPORT_URL = BASE_URL + 'admin.php'

  def init_session
    @session = Mechanize.new
    @session.post(REPORT_URL, :login => username,  :password => password, :submitter => 1)
  end
    
  public

  def initialize(args)
    super
    self.report_names = get_report_names
    self
  end

  def import_class ; TbaWebtixImport ; end

  def get_report_names
    init_session
    names = {}
    @session.get "#{REPORT_URL}?module=reports&Reports=ShowList" do |page|
      page.search("//select[@name='Show']/option").each do |opt|
        names[opt.content] = opt.attribute('value').value unless
          (opt.inner_text.blank? || opt.attribute('value').value.blank?)
      end
    end
    names
  end

  def get_one_file(key)
    init_session
    # make sure all options are checked for the report
    page = @session.get "#{REPORT_URL}?module=reports&Reports=ExportDbase&Type=RunRpt&Show=#{key}"
    # now download the actual file...
    result = @session.get(BASE_URL + page.search("//div[@id='wrapper']//a").first.attribute('href').value)
    return [result.body, 'application/octet-stream']
  end

end
