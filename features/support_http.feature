Feature: HTTP Support
  Armagh should have a functional HTTP Support utility

  Scenario: Get content of a page
    When I "GET" the page "page"
    Then I should see "You have successfully located the page.  Have a nice day."

  Scenario: Use cookies in a session
    When I "GET" the page "check_cookie"
    Then I should see "Bummer dude.  No cookies for you.  What'd you do wrong?"
    When I "GET" the page "set_cookie"
    Then I should see "Woohoo! Cookies!"
    When I "GET" the page "check_cookie"
    Then I should see "AWESOME!  Cookies for everyone."

  Scenario: Use custom header fields
    When I "GET" the page "headers" with headers:
      | Field-one | 1       |
      | Another   | Testing |
    Then I should see "Headers!"
    And I should see ""HTTP_FIELD_ONE":"1""
    And I should see ""HTTP_ANOTHER":"Testing""

  Scenario: Modify user agent
    When I "GET" the page "whats_my_agent"
    Then I should see the default agent
    When I "GET" the page "whats_my_agent" with headers:
      | User-Agent | TestAgent |
    Then I should see "Your agent is TestAgent"

  Scenario: Cookie Login with Post
    When I "GET" the page "cant_get_here_without_cookie_based_login"
    Then I should see "Please log in to continue."
    When I "POST" the page "cookie_based_login"
    Then I should see "Fail, Loser"
    When I "POST" the page "cookie_based_login" with fields:
      | secret   | wooptidoo |
      | password | friend    |
      | username | test_user |
    Then I should see "Welcome, test_user!"
    When I "GET" the page "cant_get_here_without_cookie_based_login"
    Then I should see "You made it!"

  Scenario: HTTP
    When I "GET" the site "http://www.example.com/"
    Then I should see "Example Domain"

  Scenario: HTTPS
    When I "GET" the site "https://www.example.com/"
    Then I should see "Example Domain"

  Scenario: Basic Authentication
    When I "GET" the page "http_basic_auth"
    Then I should get a "Armagh::Support::HTTP::ConnectionError" with the message "Unexpected HTTP response from 'https://testserver.noragh.com/suites/http_basic_auth': 401 - Unauthorized."
    When I "GET" the page "http_basic_auth" with auth:
      | user | testuser |
      | pass | testpass |
    Then I should see "Your credentials made me happy."

  Scenario: 404
    When I "GET" the page "not_a_valid_page"
    Then I should get a "Armagh::Support::HTTP::ConnectionError" with the message "Unexpected HTTP response from 'https://testserver.noragh.com/suites/not_a_valid_page': 404 - Not Found."

  Scenario: Redirection
    When I "GET" the page "redirection"
    Then I should see "You made it to the redirection target."

  Scenario: Disabled Redirection
    Given I disabled redirection
    When I "GET" the page "redirection"
    Then I should get a "Armagh::Support::HTTP::RedirectError" with the message "Attempted to redirect from 'https://testserver.noragh.com/suites/redirection' but redirection is not allowed."

  Scenario: Infinite Redirection
    When I "GET" the page "infinite_redirection"
    Then I should get a "Armagh::Support::HTTP::RedirectError" with the message "Too many redirects from 'https://testserver.noragh.com/suites/infinite_redirection'."

  # Untested - PKI, Proxy.