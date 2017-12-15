# Divx Concourse Tasks

This repository contains reusable concourse tasks. Tasks in Concourse are essentially build steps which are 
run within a container, and can be based off any image found on Docker Hub or in a private repository. This 
means that we get reproducible environments, and that tasks can be written in any language we'd like.

The goal is to create tasks for common operations once in this repository, and then reuse them
across different projects, so that everybody benefits from each others ideas and improvements.

## Usage

The recommended way of using this repository is to declare it as a resource in your pipeline:

```yml
resources:
  - name: common-tasks
    type: git
    source:
      uri: git@github.com:TeliaSoneraNorge/divx-concourse-tasks.git
      branch: master

```

In order to access the tasks in the repository, you pull them into a job (together with your project, here called `master-branch`):

```yml
jobs:
  - name: deploy-terraform
    plan:
    - aggregate:
      - get: master-branch
        trigger: true
      - get: common-tasks
        params: { submodules: [ terraform ] }

```

In the example, we are pulling in just the `divx-concourse-tasks/terraform` directory and making it available
as `common-tasks/terraform` to tasks in our job. So to use the task we simply declare:

```yml
    - task: divx-jump-account
      file: common-tasks/terraform/0.11.1.yml
      input_mapping: { source: master-branch }
      params:
        command: test
        cache: true
        directories: |
          terraform/concourse
          terraform/vault
```

In the example, `file:` links to the task definition with the same name found in this repository, while
`input_mapping` is used to align the [expected input](https://github.com/TeliaSoneraNorge/divx-concourse-tasks/blob/master/terraform/0.11.1.yml#L10)
to the task with the `get:` resources. Everything under `params:` are parameters passed to and [expected by the task](https://github.com/TeliaSoneraNorge/divx-concourse-tasks/blob/master/terraform/0.11.1.yml#L13).
You can see how the task will be run [here](https://github.com/TeliaSoneraNorge/divx-concourse-tasks/blob/master/terraform/terraform.sh#L105-L116).

## Issues

Feel free to submit issues to this repository. Please include a detailed description.

## Contributing

Have at it, and submit a pull-request.
