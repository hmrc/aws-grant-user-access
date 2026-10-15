terraform {
  source = "../../modules//platsec_ci"
}

include {
  path = find_in_parent_folders("root.hcl")
}
