class BrownPaperTicketsDownload < BulkDownload

  def initialize(user,pass)
    @session = Mechanize.new
    @session.post('https://www.brownpapertickets.com/login.html',
      :account => 'producer',
      :login => user,
      :pass => pass)
    @report_names = get_report_names
    self
  end

  def get_report_names
    # return list of shows with SELECT option values
    report_names = {}
    @session.get 'https://www.brownpapertickets.com/salesreports.html?e_id=&d_id=&report=salesvalues&showallevents=t' do |page|
      page.search("//select[@name='e_id']/option").each do |opt|
        report_names[opt.inner_text] = opt.attribute('value').value
      end
    end
    report_names
  end
  
end
