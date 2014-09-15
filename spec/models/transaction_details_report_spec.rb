require 'spec_helper'

describe TransactionDetailsReport do
  before :each do
    @items = Array.new(5) { create :revenue_voucher }
  end
  it 'gathers the items' do
    @rep = TransactionDetailsReport.new
    @rep.from = 1.minute.ago
    @rep.to = 1.minute.from_now
    @rep.generate
    @rep.report.data.size.should == 5
  end
end
