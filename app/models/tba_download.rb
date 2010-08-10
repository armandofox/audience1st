class TBADownload < BulkDownload

  def initialize(user,pass)
    @session = Mechanize.new
    @session.post('http://tix.theatrebayarea.org/ticketing/admin.php',
      :login => user,
      :password => pass,
      :submitter => 1)
    @report_names = get_report_names
    self
  end

  def get_report_names
    names = {}
    @session.get 'http://tix.theatrebayarea.org/ticketing/admin.php?module=reports&Reports=ShowList' do |page|
      page.search("//select[@name='Show']/option").each do |opt|
        names[opt.inner_text] = opt.attribute('value').value
      end
    end
    names
  end

end
