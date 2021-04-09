# Extract AWS SecretsManager data and add to pipeline environment
add_secretsmanager_run_variables() {
  local resourceName="$1"

  # awsIntegration
  local awsIntegration
  awsIntegration=$(find_resource_variable "$resourceName" "awsIntegration")
  if [ -z "$awsIntegration" ] ; then
    echo "[declarativesystems/SecretsManager] awsIntegration is required"
    exit 1
  fi

  # obtain keys and export using the well known variables AWS SDK expects
  AWS_ACCESS_KEY_ID=$(eval echo '$int_'"${awsIntegration}"'_accessKeyId')
  if [ -z "$AWS_ACCESS_KEY_ID" ] ; then
    echo "[declarativesystems/SecretsManager] unable to obtain AWS_ACCESS_KEY_ID for integration:${awsIntegration}"
    exit 1
  fi
  export AWS_ACCESS_KEY_ID

  AWS_SECRET_ACCESS_KEY=$(eval echo '$int_'"${awsIntegration}"'_secretAccessKey')
  if [ -z "$AWS_SECRET_ACCESS_KEY" ] ; then
    echo "[declarativesystems/SecretsManager] unable to obtain AWS_SECRET_ACCESS_KEY for integration:${awsIntegration}"
    exit 1
  fi
  export AWS_SECRET_ACCESS_KEY


  # secrets
  local secrets
  secrets=$(find_resource_variable "$resourceName" "secrets")
  if [ -z "$secrets" ] ; then
    echo "[declarativesystems/SecretsManager] secrets (list of secrets to lookup) are required"
    exit 1
  fi

  # region
  local region
  region=$(find_resource_variable "$resourceName" "region")
  if [ -z "$secretId" ] ; then
    echo "[declarativesystems/SecretsManager] region is required"
  fi

  for secret in $secrets ; do
    # secretId
    local secretId
    secretId=$(echo "$secret" | awk -F= '{print $1}')
    if [ -z "$secretId" ] ; then
      echo "[declarativesystems/SecretsManager] no secretId could be parsed from ${secret}"
      exit 1
    fi

    # Expand any shell variables in secret IDs which lets us replace values at
    # runtime.
    local secretIdInterpolated
    secretIdInterpolated=$(eval echo "$secretId")

    # pipelineVariable
    local pipelineVariable
    pipelineVariable=$(echo "$secret" | awk awk -F= '{print $2}')
    if [ -z "$pipelineVariable" ] ; then
      echo "[declarativesystems/SecretsManager] no pipelineVariable could be parsed from ${secret}"
      exit 1
    fi

    # 1. blob of JSON...
    local awsOutput
    awsOutput=$(aws secretsmanager get-secret-value \
      --secret-id "${secretIdInterpolated}" \
      --region "${region}"
    )
    if [ "$?" -ne 0 ] ; then
      echo "[declarativesystems/SecretsManager] AWS sdk command failed: ${awsOutput}"
      exit 1
    fi

    # 2 . Extract secretstring...
    local secretString
    secretString=$(echo "$awsOutput" | jq -j .SecretString)
    if [ "$?" -ne 0 ] ; then
      echo "[declarativesystems/SecretsManager] extract SecretString JSON failed: ${secretString}"
      exit 1
    fi

    if [ -z "$secretString" ] ; then
      echo "[declarativesystems/SecretsManager] SecretsString (value) for ${secretId} is empty"
      exit 1
    fi

    add_run_variables "$pipelineVariable"="$secretString"
    echo "[declarativesystems/SecretsManager] added pipeline variable ${pipelineVariable}"
  done

  # destroy the AWS credentials as their presence breaks step execution
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  echo "[declarativesystems/SecretsManager] unset AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
}

execute_command add_secretsmanager_run_variables "%%context.resourceName%%"