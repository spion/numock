use original/mocked.nu

def numock-get-fn [module_name: string, fn_name: string] {
  if ($env | get -i NUMOCK_REGISTRY) == null {
    $env.NUMOCK_REGISTRY = {
        mocks: {}
    }
  }
  ($env.NUMOCK_REGISTRY.mocks | get -i $module_name | get -i $fn_name)
}


export def example_mocked_greeting [arg] {
  let f = numock-get-fn "mocked.nu" "example_mocked_greeting"
  if $f != null {
    do $f {arg:$arg}
  } else {
    mocked example_mocked_greeting $arg
  }
}