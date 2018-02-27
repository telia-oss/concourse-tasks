## Concourse pipeline

Deployment:

```bash
fly -t prod-cloudops set-pipeline -p divx-concourse-tasks -c ./.ci/pipeline.yml
fly -t prod-cloudops unpause-pipeline -p divx-concourse-tasks
```

Destroy:

```bash
fly -t prod-cloudops destroy-pipeline -p divx-concourse-tasks
```

Expose:

```bash
fly -t prod-cloudops expose-pipeline --pipeline divx-concourse-tasks
# Revert with: fly -t cloudops hide-pipeline --pipeline divx-concourse-tasks
```

### Required secrets

- Access token for setting status on PR's.
- Deploy key for pulling the repository.
