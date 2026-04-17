#!/bin/sh -l

SCANFOLDER=$1
POLICY_NAME=$2
TIMEOUT=$3
POLLING_INTERVAL=$4
SOURCE_ID=$5
AUTH_TYPE=$6
SCANID_STR="Scan launched successfully. Scan ID: "

git config --global --add safe.directory "$GITHUB_WORKSPACE"

# --- Auth resolution ---
# Input takes priority, then AUTHTYPE env var, then default to basic
AUTH_TYPE_UPPER=$(echo "$AUTH_TYPE" | tr '[:lower:]' '[:upper:]')
AUTHTYPE_UPPER=$(echo "$AUTHTYPE" | tr '[:lower:]' '[:upper:]')
OIDC_FLAG=""

if [ "$AUTH_TYPE_UPPER" = "OIDC" ] || [ "$AUTHTYPE_UPPER" = "OIDC" ]; then
    if [ -n "$CLIENTID" ]; then
        UNAME=$CLIENTID
    fi
    if [ -n "$CLIENTSECRET" ]; then
        PASS=$CLIENTSECRET
    fi
    if [ -z "$UNAME" ]; then
        echo "[ERROR] CLIENTID (or UNAME) is required for OIDC authentication."
        exit 1
    fi
    if [ -z "$PASS" ]; then
        echo "[ERROR] CLIENTSECRET (or PASS) is required for OIDC authentication."
        exit 1
    fi
    OIDC_FLAG="-at OIDC"
else
    if [ -z "$UNAME" ]; then
        echo "[ERROR] UNAME is required for basic authentication."
        exit 1
    fi
    if [ -z "$PASS" ]; then
        echo "[ERROR] PASS is required for basic authentication."
        exit 1
    fi
fi

if [ -z "$URL" ]; then
    echo "[ERROR] URL is required. See the Platform URLs table in the README."
    exit 1
fi

# --- Event handling ---
echo "[INFO] Action triggered by $GITHUB_EVENT_NAME event"
echo "[INFO] GITHUB_REF: ${GITHUB_REF}"
echo "[INFO] GITHUB_REPOSITORY: ${GITHUB_REPOSITORY}"

if [ $GITHUB_EVENT_NAME = "push" ] || [ $GITHUB_EVENT_NAME = "pull_request" ]
then
    if [ $(git diff --name-only --diff-filter=ACMRT HEAD^ HEAD | wc -l) -eq "0" ]; then
        echo "[INFO] There are no files/folders to scan."
        echo "{\"version\": \"2.1.0\",\"runs\": [{\"tool\": {\"driver\": {\"name\": \"QualysIaCSecurity\",\"organization\": \"Qualys\"}},\"results\": []}]}" > response.sarif
        exit 0
    else
        echo "[INFO] From the below files, only the files with extensions supported by IaC module are included in the scan."
        git diff --name-only --diff-filter=ACMRT HEAD^ HEAD
        foldername="qiacscanfolder_$(date +%Y%m%d%H%M%S)"
        mkdir "$foldername"
        git diff --name-only --diff-filter=ACMRT HEAD^ HEAD | while IFS= read -r file; do
            cp --parents "$file" "$foldername"
        done
        SCANFOLDER=$foldername
    fi
else
    if [ "$SCANFOLDER" = "." ]
    then
        echo "[INFO] Scanning entire repository."
    else
        echo "[INFO] Scan Directory Path is - $SCANFOLDER"
    fi
fi

# --- Build CLI args ---
echo "[INFO] Scanning Started at - $(date +"%Y-%m-%d %H:%M:%S")"
EXTRA_ARGS=""
if [ -n "$TIMEOUT" ] && [ "$TIMEOUT" != "600" ]; then
    EXTRA_ARGS="--timeout $TIMEOUT"
fi
if [ -n "$POLLING_INTERVAL" ] && [ "$POLLING_INTERVAL" != "30" ]; then
    EXTRA_ARGS="$EXTRA_ARGS --interval $POLLING_INTERVAL"
fi
if [ -n "$SOURCE_ID" ]; then
    EXTRA_ARGS="$EXTRA_ARGS --source $SOURCE_ID"
fi
if [ -n "$OIDC_FLAG" ]; then
    EXTRA_ARGS="$EXTRA_ARGS $OIDC_FLAG"
fi

if [ -n "$POLICY_NAME" ]; then
    qiac scan -a $URL -u $UNAME -p $PASS -d $SCANFOLDER -m json -n GitHubActionScan --tag [{\"BRANCH_NAME\":\"$GITHUB_REF\"},{\"REPOSITORY_NAME\":\"$GITHUB_REPOSITORY\"}] -pn "$POLICY_NAME" $EXTRA_ARGS > /result.json
else
    qiac scan -a $URL -u $UNAME -p $PASS -d $SCANFOLDER -m json -n GitHubActionScan --tag [{\"BRANCH_NAME\":\"$GITHUB_REF\"},{\"REPOSITORY_NAME\":\"$GITHUB_REPOSITORY\"}] $EXTRA_ARGS > /result.json
fi
if [ $? -ne 0 ]; then
   exit 1
fi

LEN=${#SCANID_STR}
let "LEN+=1"
SCAN_ID="$(grep "$SCANID_STR" /result.json  | cut -c $LEN-)"

if [ ! -z "$SCAN_ID" ]
then
   echo "[INFO] Scan ID:" $SCAN_ID
   if [ -n "$OIDC_FLAG" ]; then
      qiac getresult -a $URL -u $UNAME -p $PASS -i $SCAN_ID -m SARIF -s -at OIDC > /raw_result.sarif
   else
      qiac getresult -a $URL -u $UNAME -p $PASS -i $SCAN_ID -m SARIF -s > /raw_result.sarif
   fi
fi

if [ -f scan_response_*.sarif ]; then
    mv scan_response_*.sarif response.sarif
    chmod 755 response.sarif
else
   echo "{\"version\": \"2.1.0\",\"runs\": [{\"tool\": {\"driver\": {\"name\": \"QualysIaCSecurity\",\"organization\": \"Qualys\"}},\"results\": []}]}" > response.sarif
fi

echo "[INFO] Scanning Completed at - $(date +"%Y-%m-%d %H:%M:%S")"
echo " "
echo "SCAN RESULT"
cd /
python resultParser.py result.json
