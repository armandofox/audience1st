require 'spec_helper'

describe ValidVouchersController do
  fixtures :customers
  before(:each) { login_as :boxoffice_manager }
  describe 'create' do
    context 'when no valid-vouchers are specified' do
      before(:each) do
        request.env['HTTP_REFERER'] = 'http://test.host'
        post :create, {:valid_voucher => {} }
      end
      it 'should redirect back to the new action' do
        response.should redirect_to 'http://test.host'
      end
      it 'should display a message' do
        flash[:notice].should match /select 1 or more show dates/i
      end
    end
  end
end
