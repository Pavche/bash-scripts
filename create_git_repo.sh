#!/usr/bin/env bash
mkdir test_repo
git init test_repo/
cd test_repo/
echo "Test repo" > README.md
git config user.name "Pavlin Georgiev"
git config --global --edit
sudo git config --system core.editor vim
git add *
git commit -m "Create test repository."
git remote add origin https://github.com/Pavche/test_repo.git
git push --set-upstream origin master
