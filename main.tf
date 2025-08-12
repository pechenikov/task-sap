terraform {
  backend "gcs" {
    bucket="pechenikov_cluster_state"
#    prefix="back-end"
  }
}


#resource "google_storage_bucket" "pechenikov_cluster_state" {
#  name          = "pechenikov_cluster_state"
#  location      = "europe-west1"  # or US, ASIA, etc.
#  storage_class = "STANDARD"  # or NEARLINE, COLDLINE, ARCHIVE
#  force_destroy = true#

#  uniform_bucket_level_access = true  # recommended for IAM-style access


#}



resource "google_project_service" "container_api" {
  service = "container.googleapis.com"
  project = "pechenikov-cluster"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_sql_admin" {
  service = "sqladmin.googleapis.com"
  project = "pechenikov-cluster"
}

resource "google_container_cluster" "cluster" {
  depends_on = [google_project_service.container_api]
  name     = "pechenikov-cluster"
  location = "europe-west1"
  deletion_protection = false
  enable_autopilot = true
  initial_node_count = 1

}

resource "google_sql_database_instance" "test_mysql" {
  depends_on = [google_project_service.cloud_sql_admin]
  name             = "test-mysql"
  region           = "europe-west1"
  database_version = "MYSQL_8_0"

  settings {
    tier              = "db-n1-standard-2"     # Standard VM tier (2 vCPU, 8GB RAM)
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = 10
    activation_policy = "ALWAYS"

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"    # Time in UTC
      point_in_time_recovery_enabled = false
      binary_log_enabled = true
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }  
    }


    

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "allow-external"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = false
}

resource "google_sql_user" "wordpress_user" {
  depends_on = [google_sql_database_instance.test_mysql]
  name     = "wordpress"
  instance = google_sql_database_instance.test_mysql.name
  password = "62BB262788B3278668C68EAFEE134179"
}

resource "google_sql_database" "wordpress_db" {
  depends_on = [google_sql_database_instance.test_mysql]
  name     = "wordpress_db"
  instance = google_sql_database_instance.test_mysql.name
}