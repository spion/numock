use api.nu *

export def get-user-details [id: string] {
  let user = (get-user $id)  # This calls api.nu's get-user
  return {
    id: $id,
    display_name: $"($user.first_name) ($user.last_name)",
    contact: $user.email
  }
}