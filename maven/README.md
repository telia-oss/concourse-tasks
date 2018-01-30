## Concourse task for maven

### Usage

```yml
- task: maven-test
  attempts: 2
  timeout: 10m
  file: common-tasks/maven/install.yml
  input_mapping: { source: git }
  params:
    ...
```

### Development

TODO

```bash
```
