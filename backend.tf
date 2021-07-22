terraform {
  backend "kubernetes" {
    secret_suffix    = "foundryvtt-state"
    load_config_file = true
    namespace        = "terraform"
  }
}
