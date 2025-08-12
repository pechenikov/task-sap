# General overview and prerequisites
1. Overview:
This is a configuration of kubernetes single node (pilot test version)infrastructure which provides deployment of simple wordpress instance with attached google managed mysql. Both components have fail-over redundancy. All the infrastructure including the wordpress instance is configured in terraform 
code.

2. Prerequisites:
- Install (https://cloud.google.com/sdk/docs/install) and auth with gcloud: `gcloud auth login`
- Create and set google project:
`gcloud projects create pechenikov-cluster --name="pechenikov-cluster"`
`gcloud config set project pechenikov-cluster`
- Create system user:
`gcloud iam service-accounts create gke-admin-sa --description="Service account to manage GKE clusters" --display-name="GKE Admin Service Account"`
- Set premssions:

```

gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/container.admin"
    
gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/compute.admin"
  
  
gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
  
gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/storage.bucketViewer"

gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding pechenikov-cluster \
  --member="serviceAccount:gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com" \
  --role="roles/cloudsql.admin"

```

- Export json key for service account: 

```
gcloud iam service-accounts keys create gke-sa-key.json \
  --iam-account=gke-admin-sa@pechenikov-cluster.iam.gserviceaccount.com

```

- Create bucket for terraform state: `gcloud storage buckets create gs://pechenikov_cluster_state --location=europe-west1 --uniform-bucket-level-access`

## Cluster configuration and access to the cluster
For the purpose of the demo I am using basic pilot configuration of a google kubernetes engine cluster - single node, because of free tier limitations. In production additional node pool configuration is required. The terraform code is at https://github.com/pechenikov/task-sap . The configuration for the cluster is in the root directory. I keep to instances of code - one for cloud resources like the cluster and the database instance and on for the actual apps in folder apps. For the apps (wordpress) terraform is executed from "apps" subfolder.
1. Requirements:
    - gcloud console: https://cloud.google.com/sdk/docs/install
    - kubectl and gcloud auth plugin: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl

2. Intial setup:
After all the requirements are met download the git repo and perform the following task in main repo:
`cat gke-sa-key | base64 -d >> gke-sa-key.json`
We are converting the encoded secret for the system user. With this service user terraform accesses the cluster and google resources. Offcourse keeping such a secret in git repo is bad practice but for the sake of the demo we will do it. Normally a vault solution (Google Cloud Secret Manager) or git secret should be used for the purpose. 

3. Using system user to gain access to the cluster:
Anyone who poses the json key can access the cluster (provided the above requirements are met).
Follow the following steps:
- Needed for kubectl: `export GOOGLE_APPLICATION_CREDENTIALS="{absolute_path_to_jsonkey}"`
- Needed set kubectl to target the correct cluster: `export KUBECONFIG=~/.kube/pechenikov-cluster`
- Perform login using the json key: `gcloud auth activate-service-account --key-file={path to decoded json key}}`. You can test the logged user - `gcloud auth list`
- Download kubernetes context(kubeconfig): `gcloud container clusters get-credentials pechenikov-cluster --region europe-west1 --project pechenikov-cluster`
- Test visibility to cluster: `kubectl get pod -n application`

### Application layer:

1. Wordpress:
I am using simple setup of helm chart to deploy the app. The service type is loadbalncer with two instances(replciasets). If one crushes the other takesover and instantly a replacement pod is being started to replace the failed one. 
- to get the ip of the service(External IP): `kubectl get service -n application`
By using the ip the wordpress can be accessed.
- for testing the failover find the name of the pod instance: `kubectl get pod -n application`
- delete the pod to test failover: `kubectl delete pod {name of pod} -n application`
- With `watch -n kubectl get pod -n application` you can observe constantly the pods behaviour.


2. Mysql managed database:
The instance is created using terraform code in the root folder. Root user's name and password is again saved in plain text which for production is not a good practice. As with the json key it can be stored in a vault solution or as a git secret. 

- list available database: `gcloud sql instances list`
- see details and save them: `gcloud sql instances describe test-mysql` 
- test failover: `gcloud sql instances failover test-mysql`
- wait a minute or two and again look at details and compare: the  gceZone (current zone) changed with new one. 

For more info: https://cloud.google.com/sql/docs/mysql/configure-ha





