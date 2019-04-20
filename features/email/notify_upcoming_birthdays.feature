Feature: Box Office Manager receives birthday notification
    
    As the Box Office Manager
    So I can give customers special promotions or messages
    I want to receive emails on upcoming customer birthdays

Background:
    
    Given the following customers exist:
         | first_name | last_name | email          | created_by_admin | street        | password | password_confirmation | city | state |   zip | last_login          | updated_at |
         | MaryJane   | Weigandt  | mjw@mail.com   | true             | 11 Main St    |          |                       | Oak  | CA    | 99994 | 2011-01-03 03:00:00 | 2011-01-01 |
         | Janey      | Weigandt  | janey@mail.com | false            | 11 Main St #1 | blurgle  | blurgle               | Oak  | CA    | 99949 | 2010-01-01 04:00:00 | 2010-01-01 |
    And customer "Janey Weigandt" has a birthday on "May 13"
    And the setting "boxoffice_daemon_notify" is "mjw@mail.com"
    And the setting "send_birthday_reminders" is "2"

Scenario: Notify Box Office Manager 3 days before

    Given today is "May 10"
    Then a birthday email should be sent to "mjw@mail.com" containing "janey@mail"

    
