locals {
  name      = "dummy"
  namespace = "bastian"
  version   = "0.0.2"

	ports = {
		metrics = "8000"
		http 		= "80"
	}
	limits = {
			cpu = "200m"
			memory = "500Mi"
		}
	requests = {
		cpu = "50m"
		memory = "200Mi"
	}
}
