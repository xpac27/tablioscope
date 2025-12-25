When("I open the home page") do
  visit "/index.html"
end

Then("the player controls are disabled") do
  expect(page).to have_css("#play-pause[disabled]", visible: true)
  expect(page).to have_css("#stop[disabled]", visible: true)
  expect(page).to have_css("#player-time[hidden]", visible: :all)
end

When("I load the example AlphaTab file") do
  fixture_path = File.expand_path("../../doc/example_alphatab.atext", __dir__)
  find(:css, "#file-input", visible: :all).attach_file(fixture_path)
end

Then("the player controls are visible") do
  expect(page).to have_css("#play-pause", visible: true)
  expect(page).to have_css("#stop", visible: true)
  expect(page).to have_css("#player-time", visible: true)
end
