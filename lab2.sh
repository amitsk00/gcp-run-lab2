#!/usr/bin/sh

gcloud auth list
gcloud config list project


gcloud pubsub topics create new-lab-report
gcloud services enable run.googleapis.com


##

git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab05/lab-service
npm install express
npm install body-parser
npm install @google-cloud/pubsub




##

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service
gcloud run deploy lab-report-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --max-instances=1




##

export LAB_REPORT_SERVICE_URL=$(gcloud run services describe lab-report-service --platform managed --region us-east1 --format="value(status.address.url)")
echo $LAB_REPORT_SERVICE_URL



##

PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')
