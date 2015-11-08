class BrownPaperTicketsDownload < BulkDownload

  private

  BASE_URL = 'https://www.brownpapertickets.com'

  def init_session
    @session = Mechanize.new
    @session.post("#{BASE_URL}/login.html",
      :account => 'producer', :login => username, :pass => password)
  end
  
  public

  def initialize(args)
    super
    self.report_names = get_report_names
    self
  end

  def import_class ; BrownPaperTicketsImport ; end

  def get_report_names
    # return list of shows with SELECT option values
    init_session
    report_names = {}
    @session.get "#{BASE_URL}/salesreports.html?e_id=&d_id=&report=salesvalues&showallevents=t" do |page|
      page.search("//select[@name='e_id']/option").each do |opt|
        report_names[opt.content] = opt.attribute('value').value unless
          (opt.inner_text.blank? || opt.attribute('value').value.blank?)
      end
    end
    report_names
  end

  def get_one_file(key)
    init_session
    result = @session.get "#{BASE_URL}/downloadreports.xls?e_id=#{key}&d_id=&report=names&report_type=complete"
    return [result.body, 'application/vnd.ms-excel']
  end
end
