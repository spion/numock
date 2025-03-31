use 'mocked.nu' *

export def tested_fn [arg] {
  let greet = example_mocked_greeting $arg
  $"The greeting is ($greet)"
}