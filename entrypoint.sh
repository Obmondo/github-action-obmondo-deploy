#!/bin/bash
set -euo pipefail
set -x

if ! [[ "${API_TOKEN_GITHUB}" =~ ^ghp_ ]]; then
  echo "Personal access token doesn't have the right prefix."
  exit 1
fi

if ! [[ "${OBMONDO_DEPLOY_REPO_TARGET}" ]]; then
  echo 'Missing deployment repo.'
  exit 1
fi

deploy_repo_target="${OBMONDO_DEPLOY_REPO_TARGET}"
deploy_repo_target_branch="${OBMONDO_DEPLOY_REPO_TARGET_BRANCH:-}"

git config --global user.name "${INPUT_GIT_USER_NAME:-Obmondo}"
git config --global user.email "${INPUT_GIT_USER_EMAIL:-info@obmondo.com}"

branch_name=obmondo-deploy
# repo name without `.git`
config_repo_name=$(basename "${deploy_repo_target%%.git}")
config_repo_path="/tmp/${config_repo_name}"

if ! [[ -d "${config_repo_path}" ]]; then
  git clone "https://${API_TOKEN_GITHUB}@github.com/${deploy_repo_target}.git" "${config_repo_path}"
else
  git -C "${config_repo_path}" pull
fi

# shellcheck disable=SC2155
declare -ri branch_exists=$(git -C "${config_repo_path}" show-ref -q "${branch_name}"; echo $?)

declare -a git_checkout_args=()

if [[ "${deploy_repo_target_branch}" ]];then
   git_checkout_args+=('--track' "origin/${deploy_repo_target_branch}")
fi

git -C "${config_repo_path}" checkout -B "${branch_name}" "${git_checkout_args[@]}"

# Loop over all clusters that are defined in config repo and copy
# corresponding compiled files into cloned repo.
find "${config_repo_path}/k8s/" -mindepth 1 -maxdepth 1 -type d -not -name .\* | while read -r cluster_dir; do
  cluster_name=$(basename "${cluster_dir}")
  if ! [[ -f "${cluster_dir}/${cluster_name}-vars.jsonnet" ]]; then
    echo "Cluster ${cluster_name} missing jsonnet configuration; skipping"
    continue
  fi

  ./build/kube-prometheus/build.sh "$cluster_dir"
  git -C "${config_repo_path}" status
  git -C "${config_repo_path}" add -A
  git -C "${config_repo_path}" status
done

if git -C "${config_repo_path}" diff --quiet origin/master; then
  echo 'No changes detected'
  exit 0
fi

git -C "${config_repo_path}" commit -m 'Updated Obmondo build'
git -C "${config_repo_path}" push --force-with-lease origin HEAD

# if the branch already exists we assume that the PR has already been created
# too, and all we need to do is push, which we have done by now
if (( branch_exists )); then
  declare -a gh_pr_args=()

  if [ "${OBMONDO_DEPLOY_PULL_REQUEST_REVIEWERS:-}" ]; then
    gh_pr_args+=('--reviewer' "${OBMONDO_DEPLOY_PULL_REQUEST_REVIEWERS}")
  fi

  cd "${config_repo_path}"
  gh pr create                                         \
     --title 'Updated Obmondo build'                   \
     --body 'Auto-generated pull request from Obmondo' \
     "${gh_pr_args[@]}"
fi
