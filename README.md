# numock.nu - Proof of Concept mocking for NuShell



Sketch plan for how numock should work

On the API side:

1. Tests are defined declaratively as functions
2. export const above the tests defines which modules should be mocked and what the mocks for each
   function should be

alternative imperative api:

- mock "api.md" "fn_name" {|| registry implementation }
  - this means parsing for numock "modulename" to discover modules to be mocked

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

4. For simplicity, non-mocked dependencies of the MUT that are relative local paths have a "symlink"
   of them generated using `export use` (todo: can we use actual symlinks?)

   1. Alternatively, we could add the original directory as an include via NU_LIB_DIRS, so that if a
      module is not found locally in the mocks, its looked up from NU_LIB_DIRS next

5. The test module in its temp location is introspected and run. During run time, tests may use the
   mock-module "module.name" "function_name" {|| impl here } to modify the registry as they please,
   which would change the results

Before implementing this, to derisk the approach, we need to check if we can do this

A simple test would be as follows:

1. Define an env registry that does certain things
2. Define a function that modifes an item in the registry
3. define a function that calls an imem in the registry

The experiment worked. Couple of points worth raising:

1. The generated functions must be aware of the arguments of the original. Command introspection
   should be good enough to do this. The template is something like:

   ```nu
   export def example_mocked_greeting [arg] { # add additional arguments as needed
     let f = numock-get-fn "mocked.nu" "mock_fn"
     if $f != null {
       do $f $arg
     } else {
       # call the originally imported module (must discover the basename)
       mocked example_mocked_greeting $arg
     }
   }
   ```
