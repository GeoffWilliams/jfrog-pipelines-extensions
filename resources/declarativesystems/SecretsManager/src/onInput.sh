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
  local secretString
  secretString=$(aws secretsmanager get-secret-value \
    --secret-id "${secretId}" \
    --region ${region} | jq -j .SecretString
  )

  if [ -z "$secretString" ] ; then
    echo "SecretsManager SecretsString (value) for ${secretId} is empty"
    exit 1
  fi

  add_run_variables "$pipelineVariable"="$secretString"
  echo "added pipeline variable ${pipelineVariable} "
}

execute_command add_secretsmanager_run_variable "%%context.resourceName%%"