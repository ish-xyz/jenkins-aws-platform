jenkins:
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin\n\n"
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "$${jenkins-master-admin-user}"

  authorizationStrategy:
    globalMatrix:
      permissions:
      - "Overall/Administer:admin"
      - "Overall/Read:authenticated"
      - "Credentials/View:authenticated"
      - "Job/Build:authenticated"
      - "Job/Cancel:authenticated"
      - "Job/Read:authenticated"
      - "Metrics/HealthCheck:authenticated"
      - "Run/Replay:authenticated"
      - "Run/Update:authenticated"
      - "SCM/Tag:authenticated"
  nodes:
    - permanent:
        name: "static-agent"
        remoteFS: "/home/jenkins"
        launcher:
          jnlp:
            workDirSettings:
              disabled: true
              failIfWorkDirIsMissing: false
              internalDir: "remoting"
              workDirPath: "/tmp"

  slaveAgentPort: 50000
  agentProtocols:
    - "jnlp2"
  clouds:
${agents}


credentials:
  system:
    domainCredentials:
      - credentials:
          - basicSSHUserPrivateKey:
              scope: SYSTEM
              id: jenkins-agent-key-pair
              username: ec2-user
              passphrase: ''
              description: "Jenkins Agent SSH key pair"
              privateKeySource:
                directEntry:
                  privateKey: $${${jenkins-slave-key}}
unclassified:
    gitHubConfiguration:
      apiRateLimitChecker: ThrottleForNormalize
      endpoints:
      - apiUri: "https://api.github.com"
        name: "Github Endpoint"
    location:
      adminAddress: ish@ish-ar.io
      url: http://jenkins.ish-ar.io/
    gitSCM:
      createAccountBasedOnEmail: false
      globalConfigEmail: "jenkins@ish-ar.io"
      globalConfigName: "Jenkins"
    pollSCM:
      pollingThreadCount: 5
    simple-theme-plugin:
      elements:
      - cssUrl:
          url: "https://cdn.rawgit.com/afonsof/jenkins-material-theme/gh-pages/dist/material-green.css"
security:
  apiToken:
    creationOfLegacyTokenEnabled: false
    tokenGenerationOnCreationEnabled: false
    usageStatisticsEnabled: true
  globalJobDslSecurityConfiguration:
    useScriptSecurity: false
  sSHD:
    port: -1
jobs:
  - script: >
      node {
          stage('Download repo') {
              git branch: "experiment", url: "https://github.com/ish-xyz/jenkins-aws-platform.git"
          }

          stage('Jobs provisioning') {
              def allJobs = [:]

              for (int i = 0; i < 3; i++) {
                  def jobName = "job_${i}"
                  allJobs["job ${jobName}"] = {
                      node { 
                          stage("Create Job ${jobName}") {
                              git branch: "experiment", url: "https://github.com/ish-xyz/jenkins-aws-platform.git"
                              jobDsl targets: "jenkins-jobs/jobs/${jobName}.groovy"
                          } 
                      }
                  }
              }
              parallel allJobs
          }
      }
