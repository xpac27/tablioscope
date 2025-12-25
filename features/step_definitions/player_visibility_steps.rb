When("I open the home page") do
  visit "/"
end

Then("the player controls are not visible") do
  selectors = {
    play: "[data-testid=\"play-button\"], #play, .play, button#play, button.play",
    stop: "[data-testid=\"stop-button\"], #stop, .stop, button#stop, button.stop",
    time: "[data-testid=\"time-info\"], #time-info, .time-info, [data-role=\"time-info\"]"
  }

  expect(page).to have_no_css(selectors[:play], visible: true)
  expect(page).to have_no_css(selectors[:stop], visible: true)
  expect(page).to have_no_css(selectors[:time], visible: true)
end
