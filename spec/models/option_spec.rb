require 'rails_helper'
describe Option do
  before(:each) do
    @o = Option.first           # from seed data
    @t = Mailer::BODY_TAG
    @f = Mailer::FOOTER_TAG
  end
  describe 'valid bcc email fields' do
    cases = {
      'can be a list of emails' => 'foo@bar.com, baz@foo.edu',
      'can be a single email' => 'foo@bar.com',
      'can be empty' => ''
    }
    cases.each_key do |example|
      specify example do
        @o.transactional_bcc_email = cases[example]
        @o.valid?
        expect(@o.errors[:transactional_bcc_email]).to be_empty
      end
    end
    describe 'invalid bcc email field' do
      cases = {
        'contains invalid addresses' => 'foo, x@bar.com',
        'contains blank addresses' => 'x@bar.com,,foo@bar.com'
      }
      cases.each_key do |example|
        specify example do
          @o.transactional_bcc_email = cases[example]
          @o.valid?
          expect(@o.errors[:transactional_bcc_email]).not_to be_empty
        end
      end
    end
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

    
      
