require 'spec_helper'

describe OrdersController do
  fixtures :customers
  before do
    login_as :boxoffice_manager
  end
  describe "viewing nonexistent order" do
    before :each do ; Order.stub(:find_by_id).and_return nil ; end
    it "should have no exception" do
      lambda { get :show, :id => 5 }.should_not raise_error
    end
    it "should redirect with a message" do
      get :show, :id => 5
      response.should be_redirect
      flash[:alert].should_not be_blank
    end
  end
  describe 'destroying' do
    before :each do ; @o = create(:order) ; end
    it 'creates a Txn summarizing the order' do
      Txn.should_receive(:add_audit_record).
        with(hash_including({:order_id => @o.id}))
      delete :destroy, :id => @o.id
    end
  end
  

end
