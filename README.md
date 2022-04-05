### Introduction

This is an ansible playbook for configuring Red Hat Advanced Cluster Security (i.e. Stackrox). Specifically this configures an OpenShift authentication provider along with setting up user access to ACS in terms of access scopes and permission sets.

The playbook uses the uri module to drive the ACS API, the configuration that is created is managed the variables in vars/vars.yaml.

### Using

You can invoke the playbook by passing either username/password or API token to the playbook. To obtain the ACS API token, go to https://<acs_ui_endpoint>/main/integrations/authProviders/apitoken. Either use an existing one, or create a new one.

There are three use cases in this playbook, here are the corresponding environment variables and commands:
```shell
# - Testing ACS token:
ansible-playbook acs.yaml -e activity=testing -e api_endpoint=$ACS_API_ENDPOINT -e username=admin -e password=$ACS_ADMIN_PASSWORD
ansible-playbook acs.yaml -e activity=testing -e api_endpoint=$ACS_API_ENDPOINT -e api_token=$ACS_API_TOKEN

# - ACS instance configuration via CCM:
ansible-playbook acs.yaml -e activity=acs_config \
    -e username=admin -e password=$ACS_ADMIN_PASSWORD -e api_endpoint=$ACS_API_ENDPOINT \
    -e sso_client_id=$SSO_CLIENT_NAME -e sso_client_password=$SSO_CLIENT_PASSWORD -e sso_issuer=$SSO_ISSUER

# - ACS project set team access
ansible-playbook acs.yaml -e activity=acs_config \
    -e username=admin -e password=$ACS_ADMIN_PASSWORD -e api_endpoint=$ACS_API_ENDPOINT \
    -e project_set=$OC_PROJECT_SET -e user_list=$USERS

# NOTE:if using a credential instead, replace API Token with username+password
```


### Integrating with GitOps

Integrating this automation with an existing installation of ACS via Argo CD is very straight foward:

1. Fork the repo and update the `vars/vars.yaml` to reflect the configuration that you want

2. Update your Argo CD configuration to include a health check for Central:

```
platform.stackrox.io/Central:
    health.lua: |
    hs = {}
    if obj.status ~= nil and obj.status.conditions ~= nil then
        for i, condition in ipairs(obj.status.conditions) do
            if condition.status == "True" or condition.reason == "InstallSuccessful" or condition.reason == "UpgradeSuccessful" then
                hs.status = "Healthy"
                hs.message = "Install Successful"
                return hs
            end
        end
    end
    hs.status = "Progressing"
    hs.message = "Waiting for Central to deploy."
    return hs
```

3. Create a kubernetes job to run the playbook, this is recommended to be configured as a post-sync hook. You can see a complete example of the job I use [here](https://github.com/gnunn-gitops/cluster-config/blob/main/components/apps/acs-operator/overlays/oauth/init-acs.yaml).

Here is a diagram of how it works with Argo CD.

![GitOps Flow](docs/img/gitops-flow.png)
