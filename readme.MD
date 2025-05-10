# Jenkins

Install below plugins when you started Jenkins.

Plugins:
* Pipeline stage view
* Pipeline Utility Steps
* AWS Credentials
* AWS Steps
* Rebuild
* Ansi Color
* SonarScanner

Restart Jenkins once plugins are installed

### Manage Credentials:
* We need to add ssh credentials for Jenkins to connect to agent. I am using ID as ssh-auth
* We need to add aws credentials for Jenkins to connect with AWS for deployments. I am using
    * aws-creds-dev
    * aws-creds-prod
    * aws-creds

### Configure Agent

### Configure Jenkins Shared Libraries
* Go to Manage Jenkins -> System
* Find Global Trusted Pipeline Libraries section
* Name as jenkins-shared-library, default version main and load implicitly
* Location is https://github.com/daws-81s/jenkins-shared-library.git

Now Jenkins is ready to use.