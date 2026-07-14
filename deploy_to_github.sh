#!/usr/bin/env bash
set -euo pipefail

OWNER="gt10300407"
REPO="block-puzzle-fever"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git이 설치되어 있지 않아."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI(gh)가 설치되어 있지 않아."
  echo "맥북에서 먼저 실행: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub 로그인이 필요해. 브라우저 인증을 시작한다."
  gh auth login --hostname github.com --git-protocol ssh --web
fi

if [[ ! -f index.html ]]; then
  echo "ERROR: index.html이 같은 폴더에 없어."
  exit 1
fi

# 배포 파일만 추적한다.
cat > .gitignore <<'GITIGNORE'
.DS_Store
*.zip
GITIGNORE

cat > README.md <<'README'
# Block Puzzle Fever

모바일 브라우저에서 바로 실행 가능한 단일 HTML 블록 퍼즐 게임.

## Play
GitHub Pages 주소에서 실행.
README

if [[ ! -d .git ]]; then
  git init -b main
fi

git config user.name "gt10300407"
git config user.email "zhidaole407@gmail.com"
git add index.html README.md .gitignore deploy_to_github.sh
if ! git diff --cached --quiet; then
  git commit -m "feat: publish block puzzle fever game"
fi

if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  echo "기존 저장소 $OWNER/$REPO를 사용한다."
else
  gh repo create "$OWNER/$REPO" --public --description "Mobile block puzzle fever game" --source=. --remote=origin
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "git@github.com:$OWNER/$REPO.git"
fi

git branch -M main
git push -u origin main

# Pages를 main/root 기준으로 활성화한다. 이미 활성화된 경우 업데이트한다.
if gh api "repos/$OWNER/$REPO/pages" >/dev/null 2>&1; then
  gh api --method PUT "repos/$OWNER/$REPO/pages" \
    -f build_type=legacy \
    -f source[branch]=main \
    -f source[path]=/ >/dev/null
else
  gh api --method POST "repos/$OWNER/$REPO/pages" \
    -f build_type=legacy \
    -f source[branch]=main \
    -f source[path]=/ >/dev/null
fi

URL="https://${OWNER}.github.io/${REPO}/"
echo
echo "DEPLOY_COMPLETE"
echo "$URL"
