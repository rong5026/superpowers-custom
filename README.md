# superpowers-custom

[superpowers](https://github.com/obra/superpowers) **v6.3.0** 기반의 슬림 커스텀.
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
6. 컨트롤러 SKILL.md가 503줄(v6.2.0 기준) → 매턴 재독 = 비용

## upstream 대비 변경

내용이 실제로 바뀐 파일은 **3개**뿐. 나머지는 네임스페이스 정리(기계적)와 신규 참조 문서다.

| | 변경 | 파일 | 규모 |
|---|---|---|---|
| A | **risk-tier 리뷰** — `low` 태스크는 별도 리뷰어 dispatch 생략, implementer self-review+TDD 증거로 게이트 | `subagent-driven-development/SKILL.md` | |
| B | **모델 하드 기본값** — low→haiku, high→sonnet, 최종 리뷰만 최상위. 템플릿에 박아 "상속" 방지 | `SKILL.md` §Model + `implementer-prompt.md` | |
| C | **fix 루프 5→3 라운드** — 3라운드로 안 끝나면 = 계획 결함. 갈지 말고 판정(Ruling) 후 다음 태스크로 이월 | `SKILL.md` §Fix loop | |
| D | **디버거 dispatch** — 인프라/base 결함은 systematic-debugging 서브에이전트로. 컨트롤러 인라인 삽질 금지 | `SKILL.md` §Handle report | |
| E | **base health pre-flight** — 루프 시작 전 compile+smoke 1회. 선행 결함 앞에서 한 번에 잡음 | `SKILL.md` §Setup | |
| F | **태스크 크기 상한** — ~5파일 / ~15분 초과 시 분할 강제 | `writing-plans/SKILL.md` | |

**슬림화 수치**

| 파일 | upstream 6.3.0 | v2 |
|---|---|---|
| `subagent-driven-development/SKILL.md` | 568줄 | 240줄 |
| `subagent-driven-development/implementer-prompt.md` | 154줄 | 78줄 |

컨트롤러가 매턴 재독하던 다이어그램/예제/rationalizations는
`subagent-driven-development/references/`로 이동(신규 3개) = 재독 비용 감소.

## upstream v6.3.0에서 가져온 것

v6.2.0 → v6.3.0 변경분을 커스텀(A~F) 위에 얹었다. 커스텀 3파일은 수동 병합,
나머지는 6.3.0 파일 + 네임스페이스 strip.

| 6.3.0 변경 | 반영 위치 | 커스텀과의 관계 |
|---|---|---|
| **Rulings, not stalls** — 컨트롤러가 인간에게 묻는 대신 판정하고 `Ruling:` 로 원장 기록 | `SKILL.md` §Continuous execution, §Handle report, §Fix loop, §Cap | 기존 "escalate to human" 지점 대체. 단 **E(base health 실패)는 v2 예외로 STOP 유지** — 이 계획이 판정할 결함이 아님 |
| **정지 조건 4개 한정** — 파괴적/보안/워크트리 밖 부수효과/모든 경로가 추측 | `SKILL.md` §Continuous execution | +E 로 5개 |
| **Spec = 최종 권위** — 계획이 spec을 인용, 충돌은 spec 기준 | `SKILL.md` §Setup 4, `writing-plans` 템플릿 `**Spec:**` | 신규 |
| **pre-flight scan = 표** — 태스크쌍/자기일관성 행을 실제로 써야 "clean" | `SKILL.md` §Setup 5 | 기존 1줄 스캔을 대체 |
| **동일 형태 소규모 태스크 배치** — 같은 종류 1줄 수정 N개는 dispatch 1회로 | `SKILL.md` §Task Loop | F(태스크 크기 상한)와 반대 방향의 짝 — 큰 건 쪼개고, 작고 같은 건 묶음 |
| **bounded wait** — 짧은 폴링 금지, 5~10분 단위 대기 + 상태 1줄 + 미보고 자식 추적 | `SKILL.md` §Task Loop | 신규 |
| **no-subagents contract** — implementer가 리뷰어를 스폰하지 못하게 계약 | `SKILL.md` §Dispatch + `implementer-prompt.md` | B(모델 기본값)와 같은 비용 누수 차단 |
| **"Rulings I made"** — 워크스페이스 삭제 전 판정 전량 보고 | `SKILL.md` §Finish | 신규 |
| brainstorming three-path router, Codex/Hermes tool refs, finishing-a-development-branch 보강 | 해당 스킬 파일 | 커스텀 없음, 그대로 수용 |

`references/workflow.md`·`rationalizations.md`도 위 판정 모델에 맞춰 갱신.

그 외 스킬 문서는 `superpowers:` 네임스페이스만 bare로 정리(내용 동일).
프로젝트 스킬은 bare 이름으로 호출되므로 상호참조가 이 이름과 일치해야 한다.

## 설치 (대상 repo에)

```bash
./install.sh /path/to/your-repo          # Claude + Codex 둘 다
./install.sh /path/to/your-repo --claude-only
./install.sh /path/to/your-repo --codex-only
```

스킬은 **런타임 중립**이라 Claude·Codex가 같은 파일을 그대로 읽는다(변환 없음).
install.sh가 `skills/`·`hooks/`를 대상 repo의 `.claude/`와 `.codex/`에 배치한다.

- **Claude**: `settings.hooks.json`의 `SessionStart` 엔트리를 대상 `.claude/settings.json`에 머지 → using-superpowers bootstrap 주입 → 자동 트리거.

## Codex 지원 (실측 검증됨)

**repo-owned `.codex/skills/` 경로를 쓴다.** `install.sh`가 배치한다. 실제
codex CLI(0.147.0)로 검증한 결과:
- Codex가 프로젝트 `.codex/skills/`를 자동 로드하고 using-superpowers 내용을 세션
  지침으로 활성화한다 (bootstrap **주입됨**).
- 스킬 이름은 **bare** (`subagent-driven-development`, `brainstorming`) — Claude와 일치.
- 캐노니컬 acceptance 테스트 통과: `"Let's make a react todo list"` 입력 시
  **brainstorming 스킬이 코드 작성 전에 자동 트리거**됨.

### Codex 플러그인으로는 설치하지 말 것

`codex plugin add`(마켓플레이스 플러그인) 경로는 이 포크에서 **깨진다**:
- Codex 플러그인은 스킬을 `superpowers:` 로 **네임스페이스**한다 → 이 포크의 bare
  상호참조가 안 풀려 체이닝이 깨진다.
- 플러그인 훅 `hooks/hooks.json`이 `${CLAUDE_PLUGIN_ROOT}`(Claude 전용 env)를 참조 →
  Codex에선 비어서 bootstrap 훅이 실행돼도 스크립트를 못 찾는다.

repo-owned 경로는 이 두 문제를 다 피한다. 그래서 Codex는 플러그인이 아니라
`.codex/skills/`로 쓴다.

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
