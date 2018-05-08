FactoryBot.define do

  factory :customer do
    transient do
      role 'patron'
      created_by_admin false
    end
    sequence(:first_name) { |n| "Joe#{n}" }
    sequence(:last_name) { |n| "Doe#{n}" }
    sequence(:email) { |n| "joe#{n}@yahoo.com" }
    password 'pass'
    password_confirmation { password }
    day_phone '212-555-5555'
    street '123 Fake St'
    city 'New York'
    state 'NY'
    zip '10019'

    after(:build) do |customer,e|
      customer.salt = 'abcdefghij'
      customer.crypted_password = Customer.password_digest(customer.password, customer.salt)
      customer.role = Customer.role_value(e.role)
      customer.created_by_admin = e.created_by_admin
    end

    factory :staff do
      first_name 'Sally'
      last_name 'Staffer'
      role 'staff'
    end

    factory :boxoffice do
      first_name 'Barry'
      last_name 'Boxoffice'
      role 'boxoffice'
    end

    factory :boxoffice_manager do
      first_name 'Mary'
      last_name 'Manager'
      role 'boxoffice_manager'
    end
  end

end
