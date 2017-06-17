require 'rails_helper'


class Customer
  def to_mailchimp
    {:FNAME => self.first_name, :LNAME => self.last_name, :email => self.email }
  end
  def ==(other)
    other.kind_of?(Customer) &&
      Customer.content_columns.map(&:name).all? { |c| self.send(c) == other.send(c) }
  end
end

describe EmailList do
  before(:each) do
    EmailList.stub!(:init_hominid).and_return(true)
  end
  describe "segments" do
  end
end

