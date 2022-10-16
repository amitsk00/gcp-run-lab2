#!/usr/bin/sh

gcloud auth list
gcloud config list project

gcloud services enable run.googleapis.com

git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab03

read -n 1 -p "enter Y after JS file changes are over" q1

npm install express
npm install body-parser
npm install child_process
npm install @google-cloud/storage

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter

read -n 1 -p "BUILD progress checked?" q2

gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated \
  --max-instances=1

SERVICE_URL=$(gcloud beta run services describe pdf-converter --platform managed --region us-east1 --format="value(status.url)")
echo $SERVICE_URL

read -n 1 -p "RUN progress checked?" q2


##

curl -X POST $SERVICE_URL
curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL



##

gsutil mb gs://$GOOGLE_CLOUD_PROJECT-upload
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-processed

read -n 1 -p "GCS progress checked?" q2

##
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload
read -n 1 -p "PUB progress checked?" q2


##
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
gcloud beta run services add-iam-policy-binding pdf-converter --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region us-east1

gcloud projects list
PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
gcloud beta pubsub subscriptions create pdf-conv-sub --topic new-doc --push-endpoint=$SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

read -n 1 -p "SUB progress checked?" q2

##
gsutil -m cp gs://spls/gsp644/* gs://$GOOGLE_CLOUD_PROJECT-upload

read -n 1 -p "is RUN completed?" q2

gsutil ls gs://$GOOGLE_CLOUD_PROJECT-upload/*
gsutil -m rm gs://$GOOGLE_CLOUD_PROJECT-upload/*


##

read -n 1 -p "are files updated?" q2

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter

read -n 1 -p "BUILD progress checked?" q2


gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region us-east1 \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --max-instances=1 \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed

read -n 1 -p "RUN progress checked?" q2

curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL

gsutil -m cp gs://spls/gsp644/* gs://$GOOGLE_CLOUD_PROJECT-upload

