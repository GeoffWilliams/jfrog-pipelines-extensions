# Extract AWS SecretsManager data and add to pipeline environment
add_secretsmanager_run_variable() {
  local resourceName="$1"

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

  # run AWS cli and extract the secret value, add to build pipeline

  echo "aws shared credentials file: ${AWS_SHARED_CREDENTIALS_FILE})"
  ls -l ${AWS_SHARED_CREDENTIALS_FILE} || echo missing
  echo "AWS_CONFIG_FILE ${AWS_CONFIG_FILE}"
  ls -l ${AWS_CONFIG_FILE} || echo missing
  env

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