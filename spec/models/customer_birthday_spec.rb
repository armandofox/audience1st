require 'rails_helper'

describe Customer, "birthdays" do
  before :each do
    @c1 = create(:customer)
    @c2 = create(:customer)
    @c1.update_attributes!(:birthday => 'Jan 5, 1968')
    @c2.update_attributes!(:birthday => 'Feb 4, 1974')
  end
  describe "setting" do
    before :each do ; @birthday = Time.zone.parse("Jan 21, 1973") ; end
    it "should always be in the year 2000" do
      @c = create(:customer)
      @c.update_attribute :birthday, @birthday
      expect(@c.birthday.year).to eq(2000)
    end
  end
  describe "reporting" do
    def birthdays(from, to)
      Customer.birthdays_in_range(Time.zone.parse(from), Time.zone.parse(to))
    end
    it 'should identify birthdays within range regardless of year' do
      c = birthdays('Jan 3, 2012', 'Jan 5')
      expect(c).to include(@c1)
      expect(c).not_to include(@c2)
    end
    it 'should return empty if no birthdays' do
      expect(birthdays('Feb 5', 'Jan 3')).to be_empty
    end
  end
  describe "no email should be created" do
    before :each do
      Option.first.update_attributes!(:send_birthday_reminders => 5,
        :box_office_email => 'n@ai')
      expect(Mailer).not_to receive(:upcoming_birthdays)
    end
    specify 'when feature is turned off' do
      Option.first.update_attributes!(:send_birthday_reminders => 0)
      Customer.notify_upcoming_birthdays
    end
    specify 'when every-n value is negative' do
      Option.first.update_attributes!(:send_birthday_reminders => -2)
      Customer.notify_upcoming_birthdays
    end
    specify 'when day modulo n doesn\'t match up' do
      Option.first.update_attributes!(:send_birthday_reminders => 3,
        :box_office_email => 'n@ai')
      Timecop.travel('Jan 1, 2012') do
        Customer.notify_upcoming_birthdays
      end
    end
    specify 'when there are no customers with birthdays' do
      Timecop.travel('Jan 5, 2012') do
        allow(Customer).to receive(:birthdays_in_range).and_return([])
        Customer.notify_upcoming_birthdays
      end
    end
  end
  describe "generates email when there are upcoming birthdays and valid settings" do
    before :each do
      expect(Customer).to receive(:birthdays_in_range).and_return([@c1,@c2])
      Option.first.update_attributes!(:send_birthday_reminders => 5,
        :box_office_email => 'n@ai')
      ActionMailer::Base.deliveries = []
      Timecop.travel('Jan 5, 2012') { Customer.notify_upcoming_birthdays }
      @sent = ActionMailer::Base.deliveries
    end
    specify 'just once' do
      expect(@sent.length).to eq(1)
    end
    specify 'with a proper subject line' do
      expect(@sent.first.subject).to match(Regexp.new 'Birthdays between 01/10/12 and 01/15/12')
    end
    specify 'with both customers' do
      # email is sent as multipart MIME; we check the text part here
      body = @sent.first.parts.find  { |part| part.content_type =~ /text\/plain/ }.body.raw_source
      expect(body).to include(@c1.full_name)
      expect(body).to include(@c2.full_name)
    end
  end
end
