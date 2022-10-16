#!/usr/bin/sh

gcloud auth list
gcloud config list project


gcloud config set project \
  $(gcloud projects list --format='value(PROJECT_ID)' \
  --filter='qwiklabs-gcp')

gcloud config set run/region us-central1
gcloud config set run/platform managed

REGION=us-central1

git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07



##

npm install express
npm install body-parser
npm install child_process
npm install @google-cloud/storage







cd ~/pet-theory/lab07/unit-api-billing

IMG_NAME=billing-staging-api:0.1
STG_BILLING_SVC=public-billing-service-529

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME

gcloud run deploy $STG_BILLING_SVC \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --max-instances=1

BILLING_URL=$(gcloud beta run services describe $STG_BILLING_SVC --platform managed --region $REGION --format="value(status.url)")
echo $BILLING_URL





cd ~/pet-theory/lab07/staging-frontend-billing

IMG_NAME=frontend-staging:0.1
STG_FE_SVC=frontend-staging-service-832

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME

gcloud run deploy  $STG_FE_SVC \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --max-instances=1


FE_STG_URL=$(gcloud beta run services describe $STG_FE_SVC --platform managed --region $REGION --format="value(status.url)")
echo $FE_STG_URL







cd ~/pet-theory/lab07/staging-api-billing

IMG_NAME=billing-staging-api:0.2
PVT_BILLING_SVC=private-billing-service-221

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME

gcloud run deploy $PVT_BILLING_SVC \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME \
  --platform managed \
  --region us-central1 \
  --no-allow-unauthenticated \
  --max-instances=1



BILLING_URL=$(gcloud beta run services describe $PVT_BILLING_SVC --platform managed --region $REGION --format="value(status.url)")
echo $BILLING_URL

curl -X get -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BILLING_URL

read -n 1 -p "checked the progress?"  q3

##

BILLING_SA=billing-service-sa-362

gcloud iam service-accounts create $BILLING_SA --display-name "Billing Service Cloud Run"

read -n 1 -p "checked Billing servcie account?"  q3






##
# Prod Billing
##

cd ~/pet-theory/lab07/prod-api-billing


IMG_NAME=billing-prod-api:0.1
PROD_BILL_SVC=billing-prod-service-711

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME

gcloud run deploy $PROD_BILL_SVC \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --max-instances=1

gcloud beta run services add-iam-policy-binding $PVT_BILLING_SVC --member=serviceAccount:$BILLING_SA@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region $REGION


PROD_BILLING_URL=$(gcloud beta run services describe $PVT_BILLING_SVC --platform managed --region $REGION --format="value(status.url)")
echo $PROD_BILLING_URL

curl -X get -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_BILLING_URL

read -n 1 -p "checked the progress of Prod Billing ?"  q3








##

FE_SA=frontend-service-sa-695
IMG_NAME=XX
PROD_FE_SVC=frontend-prod-service


gcloud iam service-accounts create $FE_SA --display-name "Billing Service Cloud Run Invoker"
gcloud beta run services add-iam-policy-binding $STG_FE_SVC --member=serviceAccount:$FE_SA@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region $REGION



read -n 1 -p "This should fail here ... did it fail ?"  q3

##

cd ~/pet-theory/lab07/prod-frontend-billing


IMG_NAME=frontend-prod:0.1
PROD_FE_SVC=frontend-prod-service-505

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME

gcloud run deploy $PROD_FE_SVC \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$IMG_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=1

gcloud beta run services add-iam-policy-binding $PROD_FE_SVC --member=serviceAccount:$BILLING_SA@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region $REGION


PROD_BILLING_URL=$(gcloud beta run services describe $PROD_FE_SVC --platform managed --region $REGION --format="value(status.url)")
echo $PROD_BILLING_URL

# curl -X get -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_BILLING_URL
curl -X get  $PROD_BILLING_URL

read -n 1 -p "checked the progress of Prod FE servcie ?"  q3



##




