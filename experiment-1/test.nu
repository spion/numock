
use 'mot.nu'

def --env init-registry [] {
    if ($env | get -i NUMOCK_REGISTRY) == null {
        $env.NUMOCK_REGISTRY = {
            mocks: {}
        }
    }
}

def --env mock-module-define [module_name: string, mock_impl: record] {
  # Store the mock implementation in the registry
  $env.NUMOCK_REGISTRY.mocks = ($env.NUMOCK_REGISTRY.mocks | upsert $module_name $mock_impl)
}

def main [] {
  init-registry
  print (mot tested_fn "nameHere")

  mock-module-define "mock.nu" {
    mock_fn: {|args|
      $"Mocked greeting for ($args.arg)"
    }
  }

  print (mot tested_fn "nameHere")
}