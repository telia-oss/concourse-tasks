## Concourse task for terraform

### Usage

```yml
- task: terraform-test
  attempts: 2
  timeout: 10m
  file: common-tasks/terraform/terraform.yml
  input_mapping: { source: git }
  params:
    command: test
    directory: path/to/terraform
    access_key: ((aws-access-key))
    secret_key: ((aws-secret-key))
```

### Development

```bash
docker run \
  --volume $PWD:/source/task \
  --entrypoint source/task/terraform.sh \
  --env directory=task/test \
  --env command=test \
  --env cache=true \
  hashicorp/terraform
```
