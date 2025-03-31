# user_service_test.nu

use numock.nu *
use example.nu *
use std/assert

# Declare the module under test (required)
export const tested_module = "example.nu"

# Declare the modules that need to be mocked (Mock implementations don't need to be pre-defined)
export const mocked_modules = ["api.nu"]

export def "test example" [] {
  reset-mocks

  # Define mock implementations
  mock-module "api.nu" {
    # Define the mock versions of functions
    get-user: {|args|
      # Mock implementation
      {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com"
      }
    }
  }

  # Arrange
  let user_id = "123"

  # Act
  let result = (get-user-details $user_id)

  # Assert
  assert ($result.display_name == "Test User")
  assert ($result.contact == "test@example.com")

}

export def "test real" [] {
  reset-mocks
  let user_id = "123"
  # will fail because its a real request
  let result = get-user-details $user_id
}