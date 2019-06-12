require 'rails_helper'

describe AdminContentHelper do
  it "should be able to inspect if current user is an admin" do
    expect { helper.privileged_content_for(:boxoffice) do
        "foo"
      end
    }.not_to raise_error
  end
  context "when privilege level is high enough" do
    before :each do
      allow(helper).to receive(:current_user).and_return(mock_model(Customer, :is_boxoffice => true))
    end
    it "yields content if viewing as admin" do
      assign(:gAdminDisplay, true)
      expect(helper.privileged_content_for(:boxoffice) do ; "content" ; end).to eq("content")
    end
    it "yields nothing if viewing as patron" do
      assign(:gAdminDisplay, nil)
      expect(helper.privileged_content_for(:boxoffice) do ; "content" ; end).to be_nil
    end
  end
  it "should yield nothing if privilege level is lower" do
    allow(helper).to receive(:current_user).and_return(mock_model(Customer, :is_boxoffice => nil))
    expect(helper.privileged_content_for(:boxoffice) do ; "content" ; end).to be_nil
  end
  it "should yield nothing if privilege level is invalid" do
    allow(helper).to receive(:current_user).and_return(mock_model(Customer))
    expect(helper.privileged_content_for(:boxoffice) do ; "content" ; end).to be_nil
  end
end
