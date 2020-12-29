require 'rails_helper'
describe Option do
  before(:each) do
    @o = Option.first           # from seed data
    @t = Mailer::BODY_TAG
    @f = Mailer::FOOTER_TAG
  end
  describe "HTML email template" do
    it "must begin with DOCTYPE declaration" do
      @o.html_email_template = "<p>Hi #{@t}</p>"
      expect(@o).not_to be_valid
      expect(@o.errors[:html_email_template]).to include_match_for(/must begin with/)
    end
    it "must include one body tag" do
      @o.html_email_template = "<!DOCTYPE html><p></p>"
      expect(@o).not_to be_valid
      expect(@o.errors[:html_email_template]).to include_match_for(/contain exactly one/)
    end
    it "must not include more than 1 body tag" do
      @o.html_email_template = "<!DOCTYPE html><p>#{@t}</p><p>#{@t}</p>"
      expect(@o).not_to be_valid
      expect(@o.errors[:html_email_template]).to include_match_for(/contain exactly one/)
    end
    it "must not include more than 1 footer tag" do
      @o.html_email_template = "<!DOCTYPE html><p>#{@t}</p><p>#{@f}</p><div>#{@f}</div>"
      expect(@o).not_to be_valid
      expect(@o.errors[:html_email_template]).to include_match_for(/cannot contain more than one occurrence/)
    end
    it "is valid if includes doctype and 1 body tag and 1 footer" do
      @o.html_email_template = "<!DOCTYPE html><p>#{@t}</p>#{@f}"
      expect(@o).to be_valid
    end
    it "is valid if includes doctype and 1 body tag and no footer" do
      @o.html_email_template = "<!DOCTYPE html><p>#{@t}</p>"
      expect(@o).to be_valid
    end
  end
end

    
      
