properties([
  buildDiscarder(logRotator(daysToKeepStr: '3', numToKeepStr: '7')),
])

def call(args) {
  node {
    try {
      stage('checkout') {
        checkout scm
      }
      stage('init and plan') {
        ansiColor('xterm') {
          sh """#!/bin/bash
              set -x
              export PATH="\$HOME/.tfenv/bin:\$PATH"
              export plugin_dir=/tmp/
              export TF_PLUGIN_CACHE_DIR="\$plugin_dir/.terraform.d/plugin-cache"
              mkdir -p \$TF_PLUGIN_CACHE_DIR
              function tfip(){
                  local workspace=\$1
                  local i=\$2
                  local tf_workspace=\$3
                  local plugin_dir=/tmp/
                  local TF_PLUGIN_CACHE_DIR="\$plugin_dir/.terraform.d/plugin-cache"
                  echo "" | tee -a \${workspace}/summary.txt
                  echo "\$i \${tf_workspace}" | tee -a \${workspace}/summary.txt
                  if [ ! -z "\$tf_workspace" ]; then
                    terraform workspace select \$tf_workspace
                  else
                    terraform init -input=false -upgrade
                    exit_code=\$?
                    if [ \$exit_code -ne 0 ] ; then
                      echo "Failed init"| tee -a \${workspace}/summary.txt
                      echo "" >> \${workspace}/summary_errors.txt
                      echo "\$i \${tf_workspace}" >> \${workspace}/summary_errors.txt
                      echo "Failed init" >> \${workspace}/summary_errors.txt
                      return
                    fi
                  fi
                  
                  terraform plan -lock-timeout=60s -parallelism=20 -detailed-exitcode -out plan
                  exit_code=\$?
                  if [ \$exit_code -eq 0 ] ; then
                    echo "No diff :)" | tee -a \${workspace}/summary.txt
                    return
                  fi
                  if [ \$exit_code -eq 1 ] ; then
                    echo "Failed plan" | tee -a \${workspace}/summary.txt
                    echo "" >> \${workspace}/summary_errors.txt
                    echo "\$i \${tf_workspace}" >> \${workspace}/summary_errors.txt
                    echo "Failed plan" >> \${workspace}/summary_errors.txt
                    return
                  fi
                  if ! terraform show -json plan > salida; then
                    echo "Failed show " | tee -a \${workspace}/summary.txt
                    echo "" >> \${workspace}/summary_errors.txt
                    echo "\$i \${tf_workspace}" >> \${workspace}/summary_errors.txt
                    echo "Failed show " >> \${workspace}/summary_errors.txt
                    return
                  fi
                  
                  res2change=\$(cat ./salida | \
                              jq -r '.resource_changes | map(select(.change.actions[0] != "no-op")) | map("\\(.change.actions | join(",")) \\(.address)") | .[]')
                  echo "\$res2change" >> \${workspace}/summary.txt
              }
              tfenv install v1.0.11
              tfenv use v1.0.11
              workspace=\$(pwd)
              plugin_dir=/tmp/
              rm -f \${workspace}/summary.txt
              for i in \$(find . -name '*.tf' \
                  -not -path "./6-workspaces/*" \
                  -not -path "./images/*" \
                  -printf "%h\\n" | \
                  uniq) ; do
                  cd \$workspace/\$i
                  tfip \$workspace \$i
              done
              for i in "./6-workspaces"; do
                  if [ -d \$workspace/\$i/shared ]; then
                    cd \$workspace/\$i/shared
                    tfip \$workspace \$i/shared
                  fi
                  cd \$workspace/\$i/envs
                  rm -rf .terraform
                  echo "" | tee -a \${workspace}/summary.txt
                  echo "\$i" | tee -a \${workspace}/summary.txt
                  
                  terraform init -input=false
                  exit_code=\$?
                  if [ \$exit_code -ne 0 ] ; then
                    echo "Failed init"| tee -a \${workspace}/summary.txt
                    echo "" >> \${workspace}/summary_errors.txt
                    echo "\$i \${tf_workspace}" >> \${workspace}/summary_errors.txt
                    echo "Failed init" >> \${workspace}/summary_errors.txt
                    continue
                  fi
                  for tf_workspace in \$(terraform workspace list | awk '{print \$1}' | grep -v '*'  | grep -v 'default'); do
                    echo \$tf_workspace
                    tfip \$workspace \$i/envs \$tf_workspace
                  done
              done
          """
        }
      }
      stage('Show plan') {
        println(readFile(file: 'summary.txt'))
        archiveArtifacts artifacts: 'summary.txt'
        if (fileExists('summary_errors.txt')){
          println(readFile(file: 'summary_errors.txt'))
          archiveArtifacts artifacts: 'summary_errors.txt'
        }
        if (fileExists('summary_sec.txt')){
          archiveArtifacts artifacts: 'summary_sec.txt'
        }
        if (fileExists('summary_fmt_errors.txt')){
          archiveArtifacts artifacts: 'summary_fmt_errors.txt'
        }
      }
      currentBuild.result = 'SUCCESS'
    }
    catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException flowError) {
      currentBuild.result = 'ABORTED'
    }
    catch (err) {
      currentBuild.result = 'FAILURE'
      throw err
    }
    finally {
      if (currentBuild.result == 'SUCCESS') {
        currentBuild.result = 'SUCCESS'
      }
    }
  }
}