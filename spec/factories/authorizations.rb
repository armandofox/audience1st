require 'bcrypt'
FactoryGirl.define do
  factory :authorization do
    provider "identity"
    uid "email@email.com"
    customer_id 1
    password_digest BCrypt::Password.create("pass").to_s
  end
end
