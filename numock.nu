export def --env mock-module [module_name: string, mock_impl: record] {
  # Store the mock implementation in the registry
  if ($env | get -i NUMOCK_REGISTRY) == null {
    $env.NUMOCK_REGISTRY = {
        mocks: {}
    }
  }
  $env.NUMOCK_REGISTRY.mocks = ($env.NUMOCK_REGISTRY.mocks | upsert $module_name $mock_impl)
}

export def reset-mocks [] {
  if ($env | get -i NUMOCK_REGISTRY) == null {
    $env.NUMOCK_REGISTRY = {
        mocks: {}
    }
  }
  $env.NUMOCK_REGISTRY.mocks = {}
}