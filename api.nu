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