jenkins:
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin\n\n"
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "admin"

  authorizationStrategy:
    globalMatrix:
      permissions:
      - "Overall/Administer:admin"
      - "Overall/Administer:authenticated"
      - "Overall/Read:authenticated"
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
                  privateKey: ${jenkins-slave-key}
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
          url: "https://cdn.rawgit.com/afonsof/jenkins-material-theme/gh-pages/dist/material-blue.css"
    slackNotifier:
      teamDomain: justeat
      tokenCredentialId: SLACK_TOKEN

