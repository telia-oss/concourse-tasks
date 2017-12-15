## Concourse pipeline

Deployment:

```bash
fly -t cloudops set-pipeline -p divx-concourse-tasks -c ./.ci/pipeline.yml
fly -t cloudops unpause-pipeline -p divx-concourse-tasks
```

Destroy:

```bash
fly -t cloudops destroy-pipeline -p divx-concourse-tasks
```

Expose:

```bash
fly -t cloudops expose-pipeline --pipeline divx-concourse-tasks
# Revert with: fly -t cloudops hide-pipeline --pipeline divx-concourse-tasks
```

To generate SSH keys:

```bash
ssh-keygen -t rsa -b 4096 -f ./deploy_key -N ''
vault write concourse/cloudops/divx-concourse-tasks-deploy-key value=@deploy_key
```

### Required secrets

- Access token for setting status on PR's.
- Deploy key for pulling the repository.
