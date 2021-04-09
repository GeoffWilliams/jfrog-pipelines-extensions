# Extract AWS SecretsManager data and add to pipeline environment
add_secretsmanager_run_variable() {
  local resourceName="$1"

  # awsIntegration
  local awsIntegration
  awsIntegration=$(find_resource_variable "$resourceName" "awsIntegration")
  if [ -z "$awsIntegration" ] ; then
    echo "awsIntegration is required"
  fi

  # pipelineVariable
  local pipelineVariable
  pipelineVariable=$(find_resource_variable "$resourceName" "pipelineVariable")
  if [ -z "$pipelineVariable" ] ; then
    echo "pipelineVariable is required"
  fi

  # secretId
  local secretId
  secretId=$(find_resource_variable "$resourceName" "secretId")
  if [ -z "$secretId" ] ; then
    echo "secretId is required"
  fi

  # region
  local region
  region=$(find_resource_variable "$resourceName" "region")
  if [ -z "$secretId" ] ; then
    echo "region is required"
  fi

  echo "===start env dump==="
  env
  echo "===end env dump==="

  # obtain keys and export using the well known variables AWS SDK expects
  AWS_ACCESS_KEY_ID=$(eval echo '$int_'"${awsIntegration}"'_accessKeyId')
  if [ -z "$AWS_ACCESS_KEY_ID" ] ; then
    echo "[SecretsManager] unable to obtain AWS_ACCESS_KEY_ID for integration:${awsIntegration}"
  fi
  export AWS_ACCESS_KEY_ID

  AWS_SECRET_ACCESS_KEY=$(eval echo '$int_'"${awsIntegration}"'_secretAccessKey')
  if [ -z "$AWS_SECRET_ACCESS_KEY" ] ; then
    echo "[SecretsManager] unable to obtain AWS_SECRET_ACCESS_KEY for integration:${awsIntegration}"
  fi
  export AWS_SECRET_ACCESS_KEY

  # 1. blob of JSON...
  local awsOutput
  awsOutput=$(aws secretsmanager get-secret-value \
    --secret-id "${secretId}" \
    --region "${region}"
  )
  if [ "$?" -ne 0 ] ; then
    echo "[SecretsManager] AWS sdk command failed: ${awsOutput}"
    exit 1
  fi

  # 2 . Extract secretstring...
  local secretString
  secretString=$(echo "$awsOutput" | jq -j .SecretString)
  if [ "$?" -ne 0 ] ; then
    echo "[SecretsManager] extract SecretString JSON failed: ${secretString}"
    exit 1
  fi

  if [ -z "$secretString" ] ; then
    echo "[SecretsManager] SecretsString (value) for ${secretId} is empty"
    exit 1
  fi

  add_run_variables "$pipelineVariable"="$secretString"
  echo "[SecretsManager] added pipeline variable ${pipelineVariable} "
}

execute_command add_secretsmanager_run_variable "%%context.resourceName%%"