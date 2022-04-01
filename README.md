# Obmondo automatic deployment

This repo provides a GitHub CI action that can be used to compile an [Obmondo
Kubernetes GitOps](https://gitlab.com/Obmondo/k8sops) configuration and
automatically create a pull request against a GitOps repo.

## Configuration

A sample configuration may look like this:

```yaml
---
name: Build Obmondo configuration and pull request against GitOps repo
'on':
  - push
env:
  GITHUB_TOKEN: ${{ secrets.API_TOKEN_GITHUB }}
  OBMONDO_DEPLOY_REPO_TARGET: ${{ secrets.OBMONDO_DEPLOY_REPO_TARGET }}
  OBMONDO_DEPLOY_REPO_TARGET_BRANCH: ${{ secrets.OBMONDO_DEPLOY_REPO_TARGET_BRANCH }}
  OBMONDO_DEPLOY_PULL_REQUEST_REVIEWERS: ${{ secrets.OBMONDO_DEPLOY_PULL_REQUEST_REVIEWERS }}
jobs:
  pull-request:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    - name: Create pull request
      uses: Obmondo/github-action-obmondo-deploy@main
      env:
        API_TOKEN_GITHUB: ${{ env.GITHUB_TOKEN }}
        OBMONDO_DEPLOY_REPO_TARGET: ${{ env.OBMONDO_DEPLOY_REPO_TARGET }}
        OBMONDO_DEPLOY_REPO_TARGET_BRANCH: ${{ env.OBMONDO_DEPLOY_REPO_TARGET_BRANCH }}
        OBMONDO_DEPLOY_PULL_REQUEST_REVIEWERS: ${{ env.OBMONDO_DEPLOY_PULL_REQUEST_REVIEWERS }}
```

Because GitHub lacks non-secret environment variables for Actions, we need to
use secrets, as seen in the config above. The secrets that need configuration
are the following ones:

+ `OBMONDO_DEPLOY_REPO_TARGET`
   Target repository, e.g. `organization/my-gitops`
+ `OBMONDO_DEPLOY_REPO_TARGET_BRANCH`
   Branch in target repository to create a PR against, usually `master` or `main`.
+ `OBMONDO_DEPLOY_PULL_REQUEST_REVIEWERS`
   A comma-separated list of reviewers. Optional.
