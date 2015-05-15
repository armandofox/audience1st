require 'spec_helper'

describe Customer, "birthdays" do
  before :each do
    @c1 = create(:customer)
    @c2 = create(:customer)
    @c1.update_attributes!(:birthday => 'Jan 5, 1968')
    @c2.update_attributes!(:birthday => 'Feb 4, 1974')
  end
  describe "setting" do
    before :each do ; @birthday = Time.parse("Jan 21, 1973") ; end
    it "should always be in the year 2000" do
      @c = create(:customer)
      @c.update_attribute :birthday, @birthday
      @c.birthday.year.should == 2000
    end
  end
  describe "reporting" do
    def birthdays(from, to)
      Customer.birthdays_in_range(Date.parse(from), Date.parse(to))
    end
    it 'should identify birthdays within range regardless of year' do
      c = birthdays('Jan 3, 2012', 'Jan 5')
      c.should include(@c1)
      c.should_not include(@c2)
    end
    it 'should return empty if no birthdays' do
      birthdays('Feb 5', 'Jan 3').should be_empty
    end
  end
  describe "delivering email" do
    before :each do
      Option.stub!(:send_birthday_reminders).and_return(5)
      Option.stub!(:boxoffice_daemon_notify).and_return('n@ai')
    end
    context "should not be attempted" do
      before :each do ; Mailer.should_not_receive :deliver_upcoming_birthdays ; end
      it 'when feature is turned off' do
        Option.stub!(:send_birthday_reminders).and_return(0)
        Customer.notify_upcoming_birthdays
      end
      it 'when every-n value is negative' do
        Option.stub!(:send_birthday_reminders).and_return(-2)
        Customer.notify_upcoming_birthdays
      end
      it 'when no recipient specified in options' do
        Option.stub!(:boxoffice_daemon_notify).and_return('')
        Customer.notify_upcoming_birthdays
      end
      it 'when day modulo n doesn\'t match up' do
        Timecop.travel(Date.parse('Jan 1, 2012')) do
          Customer.notify_upcoming_birthdays
        end
      end
      it 'when there are no customers with birthdays' do
        Timecop.travel(Date.parse('Jan 5, 2012')) do
          Customer.stub!(:birthdays_in_range).and_return([])
          Customer.notify_upcoming_birthdays
        end
      end
    end
    context "when there are customers with birthdays" do
      before :each do
        Customer.stub!(:birthdays_in_range).and_return([@c1,@c2])
      end
      it 'should email report' do
        Mailer.should_receive(:deliver_upcoming_birthdays).with(
          'n@ai',
          Date.parse('Jan 10, 2012'),
          Date.parse('Jan 15, 2012'),
          [@c1,@c2])
        Timecop.travel(Date.parse('Jan 5, 2012')) do
          Customer.notify_upcoming_birthdays
        end
      end
      describe 'should generate an email' do
        before :each do
          ActionMailer::Base.deliveries = []
          Timecop.travel(Date.parse('Jan 5, 2012')) do
            Customer.notify_upcoming_birthdays
          end
          @sent = ActionMailer::Base.deliveries
        end
        it 'just once' do
          @sent.length.should == 1
        end
        it 'with a proper subject line' do
          @sent.first.subject.should match(Regexp.new 'Birthdays between 01/10/12 and 01/15/12')
        end
        it 'with both customers' do
          @sent.first.body.should include(@c1.full_name)
          @sent.first.body.should include(@c2.full_name)
        end
      end
    end
  end
end
