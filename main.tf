provider "google" {
  project = "nocrimson"
}

provider "google-beta" {
  project = "nocrimson"
}

resource "google_storage_bucket_object" "html" {
  name   = "index.html"
  source = "src/index.html"
  content_type = "text/html"
  content_language = "en"
  bucket = "${google_storage_bucket.bucket.name}"
}

resource "google_storage_object_acl" "html-acl" {
  bucket = "${google_storage_bucket.bucket.name}"
  object = "${google_storage_bucket_object.html.output_name}"
  predefined_acl = "publicRead"
}

resource "google_storage_bucket" "bucket" {
  name = "nocrimson"
  force_destroy = true
  website {
    main_page_suffix = "index.html"
  }
}

resource "google_storage_bucket_acl" "acl" {
  bucket = "${google_storage_bucket.bucket.name}"
  predefined_acl = "publicRead"
  default_acl = "publicRead"
}

resource "google_compute_backend_bucket" "backend" {
  name = "backend"
  bucket_name = "${google_storage_bucket.bucket.name}"
}

resource "google_compute_url_map" "map" {
  name = "map"
  default_service = "${google_compute_backend_bucket.backend.self_link}"
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name        = "http-proxy"
  url_map     = "${google_compute_url_map.map.self_link}"
}

resource "google_compute_target_https_proxy" "https-proxy" {
  name        = "https-proxy"
  url_map     = "${google_compute_url_map.map.self_link}"
  ssl_certificates = ["${google_compute_managed_ssl_certificate.certificate.self_link}"]
}

resource "google_compute_managed_ssl_certificate" "certificate" {
  provider = "google-beta"
  name     = "certificate"
  managed  = {
    domains = ["nocrimson.com"]
  }
}

resource "google_compute_global_forwarding_rule" "http-rule" {
  name       = "http-rule"
  target     = "${google_compute_target_http_proxy.http-proxy.self_link}"
  ip_address = "${google_compute_global_address.address.address}"
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "https-rule" {
  name       = "https-rule"
  target     = "${google_compute_target_https_proxy.https-proxy.self_link}"
  ip_address = "${google_compute_global_address.address.address}"
  port_range = "443"
}

resource "google_compute_global_address" "address" {
  name = "address"
}

output "address" {
  value = "${google_compute_global_address.address.address}"
}
