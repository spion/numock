#!/usr/bin/env nu

def introspect-module [full_module_path: string, custom_eval: string = 'null'] {
    # Run a separate Nushell process to introspect module functions
    # This avoids interference with our current environment
  let code = $"
      use ($full_module_path) *
      let __module = scope modules | where file == '($full_module_path)' | first
      let __cmd_decl_ids = $__module.commands | get decl_id
      let __commands = scope commands | where decl_id in $__cmd_decl_ids
      {
        module: $__module,
        commands: $__commands,
        custom_eval: ($custom_eval)
      } | to json
  "
  let result = nu -c $code
  $result | from json
}

def discover-module-functions [module_name: string] {
    let full_module_path = ($module_name | path expand)
    let module_data = introspect-module $full_module_path

    let result = $module_data | get commands | default []

    if ($result | is-empty) {
        error make { msg: $"Could not discover functions in module: ($module_name)" }
    }

    $result
}


const numock_get_fn = r##'
def numock-get-fn [module_name: string, fn_name: string] {
  if ($env | get -i NUMOCK_REGISTRY) == null {
    $env.NUMOCK_REGISTRY = {
        mocks: {}
    }
  }
  $env.NUMOCK_REGISTRY.mocks | get -i $module_name | get -i $fn_name
}
'##; # '


export def generate-mock-fn [module_name, fn] {

  let args = $fn | get signatures | transpose key val | get val | first

  let fn_positional_arguments = $args
    | where parameter_type == "positional"
    | get parameter_name
    | str join ', '

  mut fn_named_arguments = $args
    | where parameter_type == "named"
    | each {|param|
      if $param.short_flag == null {
        $"--($param.parameter_name)"
      } else {
        $"--($param.parameter_name)\(($param.short_flag)\)"
      }
    }
    | str join ', '

  if $fn_named_arguments != "" {
    $fn_named_arguments = $", ($fn_named_arguments)"
  }

  let fn_positional_arguments_call = $args
    | where parameter_type == "positional"
    | get parameter_name
    | each {|p| $'$($p)' }
    | str join ' '

  let fn_named_arguments_call = $args
    | where parameter_type == "named"
    | each {|param|
      $"--($param.parameter_name) $($param.parameter_name)"
    }
    | str join ' '

  let arguments_object_members = $args
    | where parameter_type == "named" or parameter_type == "positional"
    | each {|param| $"($param.parameter_name): $($param.parameter_name)" }
  let arguments_object = $"{($arguments_object_members | str join ', ')}"

  let module_base_name = $module_name | path parse | get stem

  let fn_body = $"
export def ($fn.name) [($fn_positional_arguments)($fn_named_arguments)] {
  let f = numock-get-fn "($module_name)" "($fn.name)"
  if $f != null {
    do $f ($arguments_object)
  } else {
    ($module_base_name) ($fn.name) ($fn_positional_arguments_call) ($fn_named_arguments_call)
  }
}
"
  $fn_body
}

# Generate a mock module file content
export def generate-mock-module [module_name: string] {
  let functions = discover-module-functions ($module_name | path expand)

  let additional_content = $functions | each {|fn|
    generate-mock-fn $module_name $fn
  } | str join "\n"

  $"# Auto-generated mock module

use ($module_name | path expand)
" + $additional_content + "\n" + $numock_get_fn
}



export def main [test_module] {
  # Phase 1: mock modules

  let evaluation = '{mocked_modules: $mocked_modules, tested_module: $tested_module}'
  let tests_and_mocks = introspect-module ($test_module | path expand) $evaluation
  let custom = $tests_and_mocks | get custom_eval

  let mocked_modules = $custom | get mocked_modules
  let tested_module = $custom | get tested_module

  let mock_dir = mktemp -t -d

  $mocked_modules | each {|mock_module|
    let mock_module_content = generate-mock-module $mock_module
    let mock_module_file = ($mock_dir | path join $mock_module)
    $mock_module_content | save -f $mock_module_file
  }
  # TODO: analyze module structure and extract common directories + form the directory tree
  cp $tested_module $mock_dir
  cp $test_module $mock_dir



  let test_commands = discover-module-functions ($test_module | path expand)
    | where name =~ '^test'
    | get name

  let tested_module_location = ($tested_module | path expand | path dirname);
  let new_NU_LIB_DIRS = ([$tested_module_location] | append ($env.NU_LIB_DIRS | default []))
  let new_env_config = $"$env.NU_LIB_DIRS = ($new_NU_LIB_DIRS | to nuon)\n"
  let new_env_config_path = ($mock_dir | path join ".env.nu")

  $new_env_config | save -f $new_env_config_path

  let commands_part = $test_commands | each {|cmd|
    $'print "Running test: ($cmd)"; ($cmd)'
  } | str join "\n"

  let target_module_path = $"($mock_dir)/($test_module)"
  let script = $"source ($target_module_path); ($commands_part)"
  nu --env-config $new_env_config_path -c $script
}