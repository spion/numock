# user_service_test.nu

use numock.nu *
use example.nu *
use std/assert

export const tested_module = "example.nu"
export const mocked_modules = ["api.nu"]

export def "test example" [] {
  reset-mocks

  # Define mock implementations
  mock-module-define "api.nu" {
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
  let result = get-user-details $user_id # will fail because its a real request
}