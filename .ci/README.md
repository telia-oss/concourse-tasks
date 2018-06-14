## Concourse pipeline

Deployment:

```bash
fly -t prod-cloudops set-pipeline -p concourse-tasks -c ./.ci/pipeline.yml
fly -t prod-cloudops unpause-pipeline -p concourse-tasks
```

Destroy:

```bash
fly -t prod-cloudops destroy-pipeline -p concourse-tasks
```

Expose:

```bash
fly -t prod-cloudops expose-pipeline --pipeline concourse-tasks
# Revert with: fly -t prod-cloudops hide-pipeline --pipeline concourse-tasks
```
