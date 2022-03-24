# **Scripted install of CircleCI CLI and CircleCI Runner**

Works on ARM64 versions of Ubuntu 20.04. May work on other platforms with tweaks to specific settings from CircleCI documentation - https://circleci.com/docs/2.0/runner-installation/#installation

Simple to use, just set parameters at the top of the script and run it with ./circleci-runner-setup.sh

Script will assume you have not yet created a CircleCI Namespace for your organisation VCS (github.com/orgname) and will create one for you. If you already have a Namespace created, add it to the parameters anyway. When the script runs it will warn you that the Namespace already exists. This warning can be ignored the script will continue to create the resource class and configure the CircleCi Runner.

## Parameters

 - **NAME_SPACE:** Namespace for your organisation
 - **VCS_TYPE:** Type of VCS (github)
 - **ORG_NAME:** Organisation name from Github account.
 - **RESOURCE_CLASS:** Name of the resource class
 - **PERSONAL_API_TOKEN:** Create in CircleCI. Used by CircleCi CLI to authenticate to your CircleCI Server
 - **CIRCLECI_HOST:** Hostname of your CircleCI Server (default https://circleci.com)
 - **RUNNER_NAME:** Identifiable name of the runner

## **Additional commands to remove resource classes and their tokens.**

 1. Get the name of the resource class you want to delete:
`circleci runner resource-class list <your_namespace>`
 2. Copy name of the resource-class.
 3. Get the id of the token associated with the resource-class:
`circleci runner token list <resource_class_name>`
 4. Copy id of the token.
 5. Delete the token:
`circleci runner token delete <id_of_the_token>`
 6. Delete the resource-class:
`circleci runner resource-class delete <resource_class_name>`