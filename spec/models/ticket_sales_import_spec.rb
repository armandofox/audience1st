require 'spec_helper'

describe TicketSalesImport do

  describe "preview" do
    describe "should bail out with errors" do
      before :each do ; @imp = TicketSalesImport.new ; end
      it "if no show specified" do
        @imp.preview
        @imp.errors.full_messages.should include('You must specify a show.')
      end
      it "if nonexistent show specified" do
        @imp.show_id = 99999
        Show.find_by_id(99999).should be_nil
        @imp.preview
        @imp.errors.full_messages.should include('You must specify a show.')
      end
    end
  end

end
