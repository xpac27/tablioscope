Feature: Player UI visibility

  Scenario: Player controls are disabled on initial page load
    When I open the home page
    Then the player controls are disabled

  Scenario: Player controls are visible after a file is loaded
    When I open the home page
    And I load the example AlphaTab file
    Then the player controls are visible

  Scenario: Nirvana JSON loads without AlphaTab errors
    When I open the home page
    And I load the Nirvana JSON file
    Then there are no AlphaTab errors
