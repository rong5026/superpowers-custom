# superpowers-custom

[superpowers](https://github.com/obra/superpowers) v6.2.0 기반의 슬림 커스텀.
구현 단계(subagent-driven-development)가 너무 느려서, 실제 세션을 분석해 병목 6개를
겨냥해 다시 튜닝한 포크다.

- **repo-owned** — 플러그인이 아니라 대상 저장소의 `.claude/`에 스킬+훅으로 산다.
  팀원은 `git clone`만 하면 자동으로 붙는다.
- upstream 라이선스(MIT, © 2025 Jesse Vincent) 유지 — [LICENSE](LICENSE).

## 왜 만들었나 — 측정된 병목

실제 SDD 세션(18-task 대형 런 포함)을 뜯어보니 시간은 로직이 아니라 **순차 서브에이전트
dispatch 개수**에서 샜다:

1. 소수 대형 태스크가 벽시계 독식 (43/56/45분 3개 = 18-task 런의 절반)
2. 모든 태스크에 full 리뷰 + 최대 5라운드 fix 루프
3. 컨트롤러가 인프라/DB를 **직접** 붙잡고 삽질 (서브에이전트로 안 넘김)
4. base 브랜치의 선행 결함을 태스크마다 재발견
5. 모델 미지정 → 세션 최상위 모델(비쌈) 상속
6. 컨트롤러 SKILL.md가 503줄 → 매턴 재독 = 비용

## upstream 대비 변경

내용이 실제로 바뀐 파일은 **3개**뿐. 나머지는 네임스페이스 정리(기계적)와 신규 참조 문서다.

| | 변경 | 파일 | 규모 |
|---|---|---|---|
| A | **risk-tier 리뷰** — `low` 태스크는 별도 리뷰어 dispatch 생략, implementer self-review+TDD 증거로 게이트 | `subagent-driven-development/SKILL.md` | |
| B | **모델 하드 기본값** — low→haiku, high→sonnet, 최종 리뷰만 최상위. 템플릿에 박아 "상속" 방지 | `SKILL.md` §Model + `implementer-prompt.md` | |
| C | **fix 루프 5→2 라운드** — 3라운드 필요 = 계획 결함, 갈지 말고 에스컬레이트 | `SKILL.md` §Fix loop | |
| D | **디버거 dispatch** — 인프라/base 결함은 systematic-debugging 서브에이전트로. 컨트롤러 인라인 삽질 금지 | `SKILL.md` §Handle report | |
| E | **base health pre-flight** — 루프 시작 전 compile+smoke 1회. 선행 결함 앞에서 한 번에 잡음 | `SKILL.md` §Setup | |
| F | **태스크 크기 상한** — ~5파일 / ~15분 초과 시 분할 강제 | `writing-plans/SKILL.md` | |

**슬림화 수치**

| 파일 | upstream | v2 |
|---|---|---|
| `subagent-driven-development/SKILL.md` | 503줄 | 168줄 |
| `subagent-driven-development/implementer-prompt.md` | 142줄 | 70줄 |

컨트롤러가 매턴 재독하던 다이어그램/예제/rationalizations는
`subagent-driven-development/references/`로 이동(신규 3개) = 재독 비용 감소.

그 외 7개 스킬 문서는 `superpowers:` 네임스페이스만 bare로 정리(내용 동일).
프로젝트 스킬은 bare 이름으로 호출되므로 상호참조가 이 이름과 일치해야 한다.

## 설치 (대상 repo에)

```bash
./install.sh /path/to/your-repo          # Claude + Codex 둘 다
./install.sh /path/to/your-repo --claude-only
./install.sh /path/to/your-repo --codex-only
```

스킬은 **런타임 중립**이라 Claude·Codex가 같은 파일을 그대로 읽는다(변환 없음).
install.sh가 `skills/`·`hooks/`를 대상 repo의 `.claude/`와 `.codex/`에 배치한다.

설치 후 자동 트리거를 켜려면 SessionStart bootstrap 훅을 등록한다:
- **Claude**: `settings.hooks.json`의 `SessionStart` 엔트리를 대상 `.claude/settings.json`에 머지.
- **Codex**: 같은 SessionStart 훅을 Codex 훅 설정에 등록. `hooks/session-start`는 Codex 출력 포맷(top-level `additionalContext`)을 이미 지원한다. 등록 안 해도 스킬은 이름으로 **수동 호출** 가능.

## Codex 지원

두 가지 경로. **bootstrap 자동 트리거까지 되는 건 플러그인 경로**다.

### 경로 1 — Codex 플러그인 (권장, upstream과 동일 방식)

이 repo에 `.codex-plugin/plugin.json`이 있고 `hooks` 필드를 **생략**했다. Codex는
매니페스트에 `hooks`가 없으면 `hooks/hooks.json`(= Claude와 동일한 SessionStart
bootstrap 훅)을 **자동 발견·등록**한다. 즉 Codex 플러그인으로 설치하면 스킬 +
using-superpowers bootstrap이 같이 붙어 자동 트리거가 된다 — upstream이 Codex를
붙이는 바로 그 메커니즘. (upstream은 마켓플레이스 배포판에서 `hooks:{}`로 이걸
일부러 끈다.)

Codex 플러그인으로 이 repo를 추가하면 된다(Codex 마켓플레이스/로컬 플러그인 경로는
Codex 버전 문서 참조).

### 경로 2 — repo-owned (`.codex/skills/`)

`install.sh`가 `.codex/skills/`에 스킬을 복사한다. 스킬은 이름으로 **수동 호출**
가능하지만, 플러그인이 아니라 `hooks/hooks.json` 자동 발견이 안 걸리므로 bootstrap
자동 트리거는 보장되지 않는다(= upstream 기준 "dead weight" 위험). 자동 트리거가
필요하면 경로 1을 쓴다.

### 공통

- 스킬은 harness 중립 = 변환 없이 같은 파일.
- **네임스페이스 검증**: 이 포크는 상호참조를 bare 이름으로 strip했다. Codex 플러그인이
  스킬을 `superpowers:` 로 네임스페이스하면 bare 참조가 안 풀릴 수 있다. 첫 Codex
  세션에서 `brainstorming`/`subagent-driven-development` 체이닝이 실제로 트리거되는지
  확인하고, 안 되면 참조에 `superpowers:` 를 복원한다.

## 검증 (트리거 실제로 붙는지)

```bash
# 1) 네임스페이스 잔재 0 이어야
grep -rn 'superpowers:' "$TARGET/.claude/skills" --include='*.md' | wc -l
```

2. 새 세션에서 SessionStart 훅 출력에 `You have superpowers` bootstrap이 뜨는지.
   안 뜨면 `settings.json` 머지/우선순위 문제 = 자동 트리거 안 됨.
3. "이 계획 실행해줘" 류에 `subagent-driven-development`가 자동 트리거되는지.

> 기존 superpowers **플러그인**이 별도 설치돼 있으면 중복 로드되니 제거할 것.

## 모델 tier 조정

`SKILL.md` §Model Defaults 테이블 한 곳에서 tier 이름을 네 환경(Haiku 4.5 / Sonnet 5 /
Opus 등)에 맞게 바꾸면 된다.
