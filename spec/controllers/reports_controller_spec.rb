require 'spec_helper'

describe ReportsController do
  describe 'transaction report' do
    before :each do
      @vouchers = Array.new(3) { create :revenue_voucher }
    end
    it 'test' do
      puts @vouchers.first.inspect
    end
  end
end
