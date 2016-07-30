require_relative '../../lib/armagh/support/http'

def get_method(method = 'get')
  case method.downcase
    when 'get'
      Armagh::Support::HTTP::GET
    when 'post'
      Armagh::Support::HTTP::POST
    else
      raise "Unknown method #{method}.  Should be get or post"
  end
end

Before do
  @http = Armagh::Support::HTTP::Connection.new
  @content = {}
  @error = nil
end

Given(/^I disabled redirection$/) do
  @http = Armagh::Support::HTTP::Connection.new(follow_redirects: false)
end

When(/^I "([^"]*)" the page "([^"]*)"$/) do |method, page|
  method = get_method method
  begin
    response = @http.fetch(File.join(TEST_URL, page), method: method)
    @head = response['head']
    @content = response['body']
  rescue => e
    @error = e
  end
end

When(/^I "([^"]*)" the site "(.*)"$/) do |method, url|
  method = get_method method
  begin
    response = @http.fetch(url, method: method)
    @head = response['head']
    @content = response['body']
  rescue => e
    @error = e
  end
end

When(/^I "([^"]*)" the page "([^"]*)" with headers:$/) do |method, page, table|
  method = get_method method
  headers = table.rows_hash
  begin
    response = @http.fetch(File.join(TEST_URL, page), method: method, headers: headers)
    @head = response['head']
    @content = response['body']
  rescue => e
    @error = e
  end

end

When(/^I "([^"]*)" the page "([^"]*)" with fields:$/) do |method, page, table|
  method = get_method method
  fields = table.rows_hash
  begin
    response = @http.fetch(File.join(TEST_URL, page), method: method, fields: fields)
    @head = response['head']
    @content = response['body']
  rescue => e
    @error = e
  end
end

When(/^I "([^"]*)" the page "([^"]*)" with auth:$/) do |method, page, table|
  method = get_method method
  auth = table.rows_hash
  begin
    response = @http.fetch(File.join(TEST_URL, page), method: method, auth: auth)
    @head = response['head']
    @content = response['body']
  rescue => e
    @error = e
  end
end

Then(/^I should see "(.*)"$/) do |content|
  assert_include @content, content
end


Then(/^I should see the default agent$/) do
  assert_include @content, "Your agent is #{Armagh::Support::HTTP::Connection::DEFAULT_HEADERS['User-Agent']}"
end

Then(/^I should get a "([^"]*)" with the message "(.*)"$/) do |error_class, message|
  assert_equal(error_class, @error.class.to_s)
  assert_equal(message, @error.message)
end


