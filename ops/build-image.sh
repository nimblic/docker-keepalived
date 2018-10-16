#!/bin/bash

# Only local compilation is supported (Docker 4 Mac or Docker Toolbox)

set -e

# if ! docker-machine active 2>/dev/null &>/dev/null; then
# 	echo "No docker host is defined (docker-machine active)"
#   echo "Using Docker for Mac if present"
# fi

echo '===> Building docker image...'

GIT_BRANCH=$(git name-rev --name-only HEAD | sed "s/~.*//")
GIT_COMMIT=$(git rev-parse HEAD)
GIT_COMMIT_SHORT=$(echo $GIT_COMMIT | head -c 8)
GIT_DIRTY='false'
BUILD_CREATOR=$(git config user.email)
# Whether the repo has uncommitted changes
if [[ $(git status -s --untracked-files=no) ]]; then
	GIT_DIRTY='true'
fi

docker build \
  -t quay.io/nimblic/keepalived:latest \
  -t quay.io/nimblic/keepalived:"$GIT_COMMIT_SHORT" \
  --build-arg GIT_BRANCH="$GIT_BRANCH" \
  --build-arg GIT_COMMIT="$GIT_COMMIT" \
  --build-arg GIT_DIRTY="$GIT_DIRTY" \
  --build-arg BUILD_CREATOR="$BUILD_CREATOR" \
  ./docker-keepalived

if [[ "$@" = "--push" ]]; then
  answer='y'
else
  echo ""
  echo "Push to quay?"
  echo -n "docker push quay.io/nimblic/keepalived:$GIT_COMMIT_SHORT  (y/n)"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Careful playing with stty
  echo ""
fi
if echo "$answer" | grep -iq "^y" ;then
  echo '===> Pushing to quay.io ...'
  docker push quay.io/nimblic/keepalived:$GIT_COMMIT_SHORT
fi

echo "Done"
echo ""