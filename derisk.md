Before implementing this, to derisk the approach, we need to check if the approach works

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
