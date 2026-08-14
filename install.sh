#!/usr/bin/env bash
# superpower-custom-v2 설치 — 대상 repo의 .claude/ 와/또는 .codex/ 에 스킬+훅 배치.
#
# 스킬은 런타임 중립이라 Claude·Codex가 같은 파일을 그대로 읽는다(변환 없음).
#
# Usage:
#   ./install.sh [TARGET_REPO] [--claude-only] [--codex-only]
#     TARGET_REPO    설치 대상 repo 루트 (기본: 현재 디렉터리)
#     --claude-only  .claude 만 설치
#     --codex-only   .codex 만 설치
#   (기본: 둘 다)

set -euo pipefail
BUNDLE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="$PWD"; CLAUDE=1; CODEX=1
for a in "$@"; do
  case "$a" in
    --claude-only) CODEX=0 ;;
    --codex-only)  CLAUDE=0 ;;
    -*) echo "unknown option: $a" >&2; exit 2 ;;
    *)  TARGET="$a" ;;
  esac
done
TARGET="$(cd "$TARGET" && pwd)"

install_into() {            # $1 = harness dir (.claude | .codex)
  local root="$TARGET/$1"
  mkdir -p "$root/skills" "$root/hooks"
  cp -R "$BUNDLE/skills/." "$root/skills/"
  cp -R "$BUNDLE/hooks/."  "$root/hooks/"
  chmod +x "$root/hooks/run-hook.cmd" "$root/hooks/session-start" 2>/dev/null || true
  echo "  → $root/{skills,hooks}"
}

echo "bundle: $BUNDLE"
echo "target: $TARGET"
[ $CLAUDE -eq 1 ] && install_into .claude
[ $CODEX  -eq 1 ] && install_into .codex

echo
echo "SessionStart bootstrap 훅 등록 (자동 트리거용):"
[ $CLAUDE -eq 1 ] && echo "  Claude: settings.hooks.json 의 SessionStart 엔트리를 $TARGET/.claude/settings.json 에 머지"
[ $CODEX  -eq 1 ] && echo "  Codex : 같은 SessionStart 훅을 Codex 훅 설정에 등록 (session-start 스크립트는 Codex 출력 포맷 이미 지원). 미등록 시 스킬은 이름으로 수동 호출 가능."
echo
echo "검증 (네임스페이스 잔재 0 이어야):"
echo "  grep -rn 'superpowers:' $TARGET/.claude/skills $TARGET/.codex/skills --include='*.md' 2>/dev/null | wc -l"
