require 'spec_helper'

describe ReportsController do
  # make sure to stub out before-filter that controls admin access
  before :each do
    controller.class.skip_before_filter :is_staff_filter
  end
  describe 'transaction details report' do
    before :each do
      Time.stub(:range_from_params).and_return([1.day.ago - 1.minute, 1.day.from_now])
    end
    it 'runs report' do
      TransactionDetailsReport.should_receive(:render_html)
      get :transaction_details_report
    end
    it 'renders HTML template' do
      TransactionDetailsReport.stub(:render_html).and_return('')
      get :transaction_details_report
      response.should render_template('reports/transaction_details_report')
    end
  end
end
