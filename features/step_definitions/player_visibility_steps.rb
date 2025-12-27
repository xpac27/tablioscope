When("I open the home page") do
  visit "/index.html"
end

Then("the player controls are disabled") do
  expect(page).to have_css("#play-pause[disabled]", visible: true)
  expect(page).to have_css("#stop[disabled]", visible: true)
  expect(page).to have_css("#player-time[hidden]", visible: :all)
end

When("I load the example AlphaTab file") do
  fixture_path = File.expand_path("../../documentation/examples/example_alphatab.atext", __dir__)
  find(:css, "#file-input", visible: :all).attach_file(fixture_path)
end

When("I load the Nirvana JSON file") do
  @console_messages_before = fetch_console_messages
  fixture_path = File.expand_path("../../tabs/json/nirvana-smells-like-teen-spirit-tab_g1.json", __dir__)
  find(:css, "#file-input", visible: :all).attach_file(fixture_path)
end

Then("the player controls are visible") do
  Capybara.using_wait_time(10) do
    expect(page).to have_css("#play-pause", visible: true)
    expect(page).to have_css("#stop", visible: true)
    expect(page).to have_css("#player-time", visible: true)
  end
end

Then("the player controls are visible after a long load") do
  Capybara.using_wait_time(30) do
    expect(page).to have_css("#play-pause", visible: true)
    expect(page).to have_css("#stop", visible: true)
    expect(page).to have_css("#player-time", visible: true)
  end
end

Then("there are no AlphaTab errors") do
  sleep 2
  messages = fetch_console_messages
  if @console_messages_before
    messages -= @console_messages_before
  end
  alpha_errors = messages.select { |msg| msg.match?(/AlphaTab|AlphaTex|Error AT\\d+/) }
  expect(alpha_errors).to be_empty, "AlphaTab errors:\n#{alpha_errors.join("\n")}"
end

def fetch_console_messages
  browser = page.driver.browser
  if browser.respond_to?(:console_messages)
    browser.console_messages.map do |entry|
      entry.respond_to?(:message) ? entry.message : entry[:message]
    end.compact
  else
    []
  end
end
