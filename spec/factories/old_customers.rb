FactoryGirl.define do
  factory :old_customer, :class => 'Customer' do
    transient do
      role :patron
      created_by_admin false
    end
    sequence(:first_name) { |n| "Jack#{n}" }
    sequence(:last_name) { |n| "Wan#{n}" }
    sequence(:email) { |n| "jack#{n}@qq.com" }
    sequence(:password) { |n| "old_pass#{n}" }
    password_confirmation { password }
    day_phone '123-123-1234'
    street '321 Fake St'
    city 'San Francisco'
    state 'CA'
    zip '97420'

    after(:build) do |old_customer, e|
      old_customer.salt = 'abcdefghij'
      old_customer.crypted_password = Customer.password_digest(old_customer.password, old_customer.salt)
      old_customer.role = Customer.role_value(e.role)
      old_customer.created_by_admin = e.created_by_admin
    end
  end
end