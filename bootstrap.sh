#/bin/bash

#you must run =>  gcloud auth login yourlogin@gmail.com  <= before running this script


DIR=${PWD}
NOTRANDOM=${RANDOM}

echo "Project ID(default if not stated):"
read PROJECT_ID_BASE
if [ -z ${PROJECT_ID_BASE} ]
  then
    PROJECT_ID_BASE="springboard-project"
fi
PROJECT_ID="${PROJECT_ID_BASE}-${NOTRANDOM}"

echo "Region(default if not stated):"
read REGION
if [ -z ${REGION} ]
  then
    REGION="europe-central2"
fi

echo "Service account name(default if not stated):"
read SERVICE_ACCOUNT_ID_BASE
if [ -z ${SERVICE_ACCOUNT_ID_BASE} ]
  then
    SERVICE_ACCOUNT_ID_BASE="serv-acc"
fi
SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_ID_BASE}-${NOTRANDOM}"

SA_ID="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Slack webhook URL(must be stated):"
read SLACK_WH
if [ -z "$SLACK_WH" ]
then
    echo "Missing value!"; exit $ERRCODE;
fi

echo "Billing account(must be stated):"
read BILLING_ACCOUNT
if [ -z "$BILLING_ACCOUNT" ]
then
    echo "Missing value!"; exit $ERRCODE;
fi

echo "SSH key username(must be stated):"
read SSH_USER
if [ -z "$SSH_USER" ]
then
    echo "Missing value!"; exit $ERRCODE;
fi

echo "SSH private key full path(must be stated):"
read FULL_PR_KEYS_PATH
if [ -z "$FULL_PR_KEYS_PATH" ]
then
    echo "Missing value!"; exit $ERRCODE;
fi

FULL_PUB_KEYS_PATH="${FULL_PR_KEYS_PATH}.pub"
SSH_KEY_CONTENT=`cat  ${FULL_PUB_KEYS_PATH}`
echo "${SSH_USER}:${SSH_KEY_CONTENT}" > project_key.txt

echo "Creating project"
gcloud projects create ${PROJECT_ID} 

echo "Linking billing"
gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT}

echo "Enabling required API's"
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  --project ${PROJECT_ID}
echo "1"
gcloud services enable \
  cloudbilling.googleapis.com \
  --project ${PROJECT_ID}
echo "2"
gcloud services enable \
  iam.googleapis.com \
  --project ${PROJECT_ID}
echo "3"
gcloud services enable \
  admin.googleapis.com \
  --project ${PROJECT_ID}
echo "4"
gcloud services enable \
  compute.googleapis.com \
  --project ${PROJECT_ID}
echo "5"
gcloud services enable \
  servicenetworking.googleapis.com \
    --project=${PROJECT_ID}

echo "Creating service account..."
gcloud iam service-accounts create ${SERVICE_ACCOUNT_ID} \
    --description="service account for test project" \
    --display-name="SERVICE_ACC" \
    --project=${PROJECT_ID} 

echo "Creating SA keys..."
gcloud iam service-accounts keys create ${DIR}/sa-private-key.json \
    --iam-account=${SA_ID}

echo "Adding role roles/storage.admin..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${SA_ID} \
    --role="roles/storage.admin"

echo "Adding role roles/compute.networkAdmin..."
gcloud projects add-iam-policy-binding \
  "${PROJECT_ID}" \
  --member="serviceAccount:${SA_ID}" \
  --role="roles/compute.networkAdmin" \
  --user-output-enabled false

echo "Adding role roles/resourcemanager.projectIamAdmin..."
gcloud projects add-iam-policy-binding \
  "${PROJECT_ID}" \
  --member="serviceAccount:${SA_ID}" \
  --role="roles/resourcemanager.projectIamAdmin" \
  --user-output-enabled false

echo "Adding role roles/compute.storageAdmin..."
gcloud projects add-iam-policy-binding \
  "${PROJECT_ID}" \
  --member="serviceAccount:${SA_ID}" \
  --role="roles/compute.storageAdmin" \
  --user-output-enabled false

echo "Adding role roles/iam.securityAdmin..."
gcloud projects add-iam-policy-binding \
  "${PROJECT_ID}" \
  --member="serviceAccount:${SA_ID}" \
  --role="roles/iam.securityAdmin" \
  --user-output-enabled false

echo "Adding role roles/compute.admin..."
gcloud projects add-iam-policy-binding \
  "${PROJECT_ID}" \
  --member="serviceAccount:${SA_ID}" \
  --role="roles/compute.admin" \
  --user-output-enabled false


echo "Creating envvars.sh"
cat << EOF > envvars.sh
export GOOGLE_APPLICATION_CREDENTIALS="${DIR}/sa-private-key.json"
export TF_VAR_PROJECT_ID=${PROJECT_ID}
export TF_VAR_SA=${SERVICE_ACCOUNT_ID}
export TF_VAR_ID=${NOTRANDOM}
export TF_VAR_BILLING_ACC=${BILLING_ACCOUNT}
export TF_VAR_SLACK_WH=${SLACK_WH}
export TF_VAR_SSH_USER=${SSH_USER}
export TF_VAR_FULL_PUB_KEYS_PATH=${FULL_PUB_KEYS_PATH}
export TF_VAR_FULL_PR_KEYS_PATH=${FULL_PR_KEYS_PATH}
EOF

echo "Adding SSH keys to current project"
gcloud config set project "${PROJECT_ID}"
gcloud compute project-info add-metadata --metadata-from-file=ssh-keys=project_key.txt
#rm project_key.txt