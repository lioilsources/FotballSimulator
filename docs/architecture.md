# Architektura a konvence jádra

Přesunuto z CLAUDE.md (sekce Konvence). Stručné invarianty zůstaly v CLAUDE.md.

- **Všechny konstanty v `scripts/util/tuning.gd`** — žádná magic numbers
  jinde. Je to autoload `Tuning`; čistě fyzikální skripty (`ball_physics.gd`,
  `serve_generator.gd`, `contact_model.gd`, `goal.gd`, `swipe_input.gd`) ho ale
  **preloadují jako `const T`**, aby fungovaly headless bez autoloadů a bez
  závislostí na scéně.
- Fyzika letu je vlastní integrace (semi-implicit Euler, 120 Hz physics tick
  v project.godot) — Godot RigidBody3D nemá Magnus, nepoužívat.
- Geometrie brány: `scripts/core/goal.gd` staví tyče a břevno v `_ready()`
  z `GOAL_HALF_WIDTH`/`GOAL_HEIGHT`/`POST_RADIUS` a umístí bránu na
  `-GOAL_DISTANCE`; `pitch.tscn` nemá žádné rozměry natvrdo.
- Contact model dostává i příchozí rychlost míče (lokální rámec); impuls
  vychází z relativní normálové rychlosti nárt−míč, takže slabý kontakt míč
  jen odrazí místo aby ho zastavil ve vzduchu.
- Swipe: geometrie gesta je ve statických `SwipeInput.add_point` /
  `analyze` (čisté, testované); Control uzel jen sbírá události a kreslí.
- Souřadnice: hráč na origin, kope směrem **-z**; topspin pro let -z = spin
  kolem **-x**, sidespin kolem **y**.
- Contact model (`contact_model.gd`): čistá statická funkce v lokálním rámci
  kopu (-z na bránu), převod do světa dělá `game_state`. Osa spinu = `u × t`
  (odvozeno z τ = r × F, ne tvar `swing×d` z plánu — měl obrácenou
  orientaci). Late shift posouvá kontakt **nahoru** (`+=`, překlep v plánu).
- Timing: `game_state` si při serve **pre-simuluje** trajektorii scratch
  instancí `BallPhysics` a najde ideální okamžik (klesání skrz
  `IDEAL_KICK_HEIGHT` po prvním odskoku); `timing_error` = čas puštění swipu
  minus ideál, měřeno v herním čase (nezávislé na assist slow-mo).
- Testy: čisté SceneTree skripty (bez GUT), referenční hodnoty fyziky
  z nezávislé Python implementace stejného modelu (hodnoty v hlavičce
  physics_test.gd). Autoloady v `--script` režimu fungují, ale core skripty
  stejně preloadují `const T` — drží to čistotu závislostí.
