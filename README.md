# numock.nu - Proof of Concept mocking for NuShell



Sketch plan for how numock should work

On the API side:

1. Tests are defined declaratively as functions
2. export const above the tests defines which modules should be mocked and what the mocks for each
   function should be

alternative imperative api:

- mock "api.md" "fn_name" {|| registry implementation }
  - this means parsing for numock "modulename" to discover modules to be mocked


Example test file

```nushell
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
```

Example module under test:

```nushell
# example.nu

use api.nu *

export def get-user-details [id: string] {
  let user = (get-user $id)  # This calls api.nu's get-user
  return {
    id: $id,
    display_name: $"($user.first_name) ($user.last_name)",
    contact: $user.email
  }
}
```

Example mocked module:

```nushell
# api.nu

# Original get-user
export def get-user [id: string] {
  # Real implementation that calls external API
  http get $"https://api.example.com/users/($id)"
}

# Creates a user
export def create-user [name: string, email: string] {
  # Real implementation
  http post https://api.example.com/users
}
```

There are 3 relevant files for every mock

1. test file - the module containing all the tests
2. module under test (MUT) - the module being tested
3. mocked modules (MMs) - one or more modules dependencies of the MUT that are being tested

On the implementation side, for every test file:

1. The test its copied into a new temp directory, together with the module-under-test, verbatim.

2. For every mocked module, a new module is generated in the temporary directory. This is a copy of
   the mocked module, with an implementation that checks a registry of mocks stored in
   $env.NUMOCK_REGISTRY (see existing code sketch)

3. The mock copy imports its original module by absolute path, then re-exports all of its member
   functions (found by introspection) as copies that can optinally be mocked through the registry

4. We add the original directory as an include via NU_LIB_DIRS, so that if a
   module is not found locally in the mocks, its looked up from NU_LIB_DIRS next

5. The test module in its temp location is introspected and run. During run time, tests may use the
   mock-module "module.name" {function_name: {|| impl here }} to modify the mock registry
