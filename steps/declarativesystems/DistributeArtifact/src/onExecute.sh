distributeArtifact() {
  # https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API#ArtifactoryRESTAPI-DistributeArtifact
  # POST /api/distribute
  #{
  #    "targetRepo" : "dist-repo-jfrog-artifactory",
  #    "packagesRepoPaths" : ["yum-local/jfrog-artifactory-pro-4.7.6.rpm"]
  #}

  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")

  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")

  local path
  path=$(find_step_configuration_value "path")

  if [ -n "$rtId" ] && [ -n "$repositoryName" ] && [ -n "$path" ] ; then
    setupJfrogCliRt "$rtId"

    local rtUrl
    local rtUser
    local rtApikey
    scopeArtifactoryVariables "$rtId"
#    access_token=$(jfrog rt access-token-create|jq .access_token)

    apiDistribute="${rtUrl}/api/distribute"
    echo "distribute Artifactory server: ${apiDistribute}"
    curl --fail -u"${rtUser}:${rtApikey}" -X POST "${apiDistribute}" \
      --header "Content-Type: application/json" \
      --data "{\"targetRepo\" : \"${repositoryName}\",
        \"packagesRepoPaths\" : [\"${path}\"]}"

    status=$?
  else
    echo "one or more parameters missing:"
    echo "  sourceArtifactory:${rtId}"
    echo "  repositoryName:${repositoryName}"
    echo "  path:${path}"

    status=1
  fi

  return "$status"

}

execute_command distributeArtifact