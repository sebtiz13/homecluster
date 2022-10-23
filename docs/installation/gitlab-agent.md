# GitLab agent deployment

Deploy GitLab agent to the cluster for allow **GitOps** work.

## Prerequisites

- Have cluster deployed.
- Retrieve token on tour GitLab project. For done this, please look the
  [GitLab documentation](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html).

## Deploy

Deploy it with the following command

```sh
./scripts/gitlab-agent.sh <kas url> <token>
# ⚠️ For development sandbox use the following command :
ENVIRONMENT=vm ./scripts/gitlab-agent.sh <kas url> <token>
```

Variables:

- `<kas url>`: The URL of the agent server (KAS). For deployed GitLab use `wss://kas.<domain>/` and for GitLab.com
  use `wss://kas.gitlab.com`.
- `<token>`: The token retrieved from GitLab project.
