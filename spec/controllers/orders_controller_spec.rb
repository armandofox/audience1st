require 'rails_helper'

describe OrdersController do
  before do
    login_as_boxoffice_manager
  end
  describe "viewing nonexistent order" do
    before :each do ; allow(Order).to receive(:find_by_id).and_return nil ; end
    it "should have no exception" do
      expect { get :show, :id => 5 }.not_to raise_error
    end
    it "should redirect with a message" do
      get :show, :id => 5
      expect(response).to be_redirect
      expect(flash[:alert]).not_to be_blank
    end
  end
  describe 'updating' do
    before :each do
      @o = create(:order, :vouchers_count => 2)
    end           
    it 'creates a Txn summarizing the order' do
      expect(Txn).to receive(:add_audit_record).
        with(hash_including({:order_id => @o.id})).
        exactly(2).times
      put :update, :id => @o.id, :items => @o.items.index_by(&:id)
    end
  end
  

end
