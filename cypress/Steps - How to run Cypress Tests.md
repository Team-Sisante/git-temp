# How to run Cypress Tests
- Source: git-temp/cypress/Steps - How to run Cypress Tests.md

1. Use tags
```gherkin
  @register
  Scenario: Register a new user
    When I register a new user
    Then the registration should succeed
    And the registered user is set as staff and added to Regular Users group
    And the registered user exists in the database
    And I sign out
```
```bash
ENVIRONMENT=development CYPRESS_video=false npx cypress run --spec cypress/e2e/authentication/auth-flow.feature --browser chrome --env TAGS="@register"
```
- ENVIRONMENT=development : passes ENVIRONMENT env var with value=development.
- CYPRESS_video=false
  - turns of video recording during the test.
- npx cypress run
  - runs a specific test.
- --spec cypress/e2e/authentication/auth-flow.feature
  - runs a specific feature
- --browser chrome 
  - runs test in chrome
- --env TAGS="@register"
  - runs only the specific scenario with @register tag.

Additional flags:
- --headed
  - runs in the Cypress Interactive Web Interface.
  

