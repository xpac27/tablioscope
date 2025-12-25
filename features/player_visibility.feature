Feature: Player UI visibility

  Scenario: Player controls are hidden on initial page load
    When I open the home page
    Then the player controls are not visible
