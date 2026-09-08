# ROADMAP.md — testování a vylepšení

> Audit stavu po Fázi 1 (září 2026) + plán práce pro Fázi 2/3.
> Doplňuje VOLLEY_PLAN.md (design) a CLAUDE.md (konvence, příkazy).
> Nálezy níže jsou ověřené headless během Godot 4.7.1 (Linux) — ne jen
> čtením kódu.

---

## 0. Stav projektu (audit)

### Co funguje

- Všechny tři headless testy zelené (`physics_test` 10/10, `contact_test`
  26/26, `gameplay_test` 6/6). Fyzika sedí na Python referenci s odchylkou
  0.00 %.
- Architektura drží zásady z plánu: konstanty jen v `tuning.gd`, čisté
  core skripty s `const T` preloadem, contact model jako statická funkce,
  FSM v `game_state.gd`, seedovaný serve.
- Hratelná smyčka serve → swipe → freeze-frame → let → GÓL/MIMO/NEDOLETĚL →
  další míč. Debug kopy 1/2/3, assist slow-mo (A).
- Export presety pro Android (APK) a iOS (Xcode projekt) jsou připravené.

### Nalezené chyby — **opraveno** (commit „Fix B1–B4“, regrese v testech)

| # | Kde | Problém | Ověření |
|---|-----|---------|---------|
| B1 | `game_state.gd:206` `_finish_serve` | Když hráč drží prst (assist slow-mo 0.6×) a serve skončí druhým dopadem, `swipe.enabled = false` zahodí tracking a `kick_released`/`swipe_canceled` už nepřijde. `Engine.time_scale` zůstane 0.6 přes pauzu výsledku i další serve, dokud hráč znovu neswipne. Pauza 1.4 s tím trvá 2.3 s. | Headless: touch-down v KICK_WINDOW, čekat na RESULT → `time_scale == 0.60`. |
| B2 | `contact_model.gd:52` + `game_state.gd:142` | Contact model ignoruje příchozí rychlost míče (`ball.launch(vel, …)` ji přepíše). Serve míč má v ideálu 3.6–5.3 m/s; při slabém/pozdním kontaktu míč „přilepí“ a spadne místo aby pokračoval. Plán §3.4 má signaturu `(foot_state, ball_state, timing)` — ball_state chybí. | Sonda: err 90 ms ⇒ \|vel\| = 0.5 m/s, míč se v letu zastaví. |
| B3 | `pitch.tscn` | Rozměry brány (±3.72, výška 2.44/2.5) jsou natvrdo ve scéně, duplikují `GOAL_HALF_WIDTH`/`GOAL_HEIGHT`. Změna v tuningu rozhodí vizuál vůči detekci gólu. | Čtení. |
| B4 | `swipe_input.gd:43` | `_pts` roste bez limitu po dobu držení prstu (dlouhý drag v slow-mo = tisíce bodů, `_draw` je každý frame kreslí). | Čtení. |

### Designové / tuningové nálezy (rozhodnout v tuning passu)

| # | Nález | Čísla |
|---|-------|-------|
| D1 | **Timing gaussovka je moc ostrá vůči ratingům.** `TIMING_SIGMA` = 45 ms, ale rating GOOD sahá do 70 ms. Kop hodnocený GOOD je už dud; LATE/EARLY jsou fakticky nulové. Mechanika „pozdě = nedoletí“ (late shift, §3.4/6) se tak nikdy neprojeví — energie zkolabuje dřív, než změna geometrie kontaktu něco udělá. | err 0 → 32 m/s · 30 ms → 20 m/s · **50 ms (GOOD) → 9 m/s** · 70 ms → 2.7 m/s · 90 ms → 0.5 m/s |
| D2 | **Středový zásah letí s elevací 0°.** `SWING_LIFT` ovlivňuje jen spin a účinnost, ne směr. Z výšky 0.55 m dopadá po 9.5 m (brána 18 m) a ke gólu se dokutálí. Hráč musí vždy mířit pod střed. Rozhodnout: má zdvih švihu přidávat elevaci (přirozený volej)? | offset 0 → vel (0, 0, −31.4) |
| D3 | **Timing = okamžik puštění prstu, bez švihu nohy.** `foot_swing.gd` z plánu neexistuje; kontakt je instantní. Pro pocit a pro Fázi 2 (vizuální noha) bude potřeba zpoždění švihu, což posune kalibraci timingu. | — |
| D4 | **Směr swipu se nepoužívá.** Swipe dolů = swipe nahoru. Zvážit: vyžadovat směr „od hráče“ nebo z něj odvodit `swing_dir` (dnes konstantní). | — |
| D5 | `CURVE_SPIN` při plném oblouku dává 56 rad/s (9 ot/s) → boční zrychlení ~8.5 m/s². Extrémní offset 0.9 dává 72 rad/s a jen 13.7 m/s. Zkontrolovat pocitově, jestli faleš není příliš laciná oproti offsetu. | — |
| D6 | Timing error je kvantovaný na physics tick (8.3 ms) — `_serve_time` se sčítá v `_physics_process`, release přichází ve frame. Pro PERFECT okno 30 ms je to OK, ale s touch latencí (§9 plánu) to sčítá. | — |

### Mezery v testech

- ~~`swipe_input.gd` nemá žádný test~~ — vyřešeno (`swipe_test.gd`).
- `game_state.gd`: netestováno MIMO, NEDOLETĚL, POZDĚ (bez švihu), VZDUCH
  (MISS → druhý dopad), interpolace `_check_goal_crossing` na hraně tyče,
  fallback `_presim_ideal_time` (apex < `IDEAL_KICK_HEIGHT`).
- `ball_physics.gd`: netestován přenos spinu při odskoku (topspin zrychlí
  xz), přechod do kutálení a `ball_stopped`, útlum spinu.
- `serve_generator.gd`: test kop-zóny běží na 10 seedech; není garance, že
  ideál je vždy dosažitelný (sonda: 0/200 serve s apexem pod ideálem — ale
  není to test, je to náhoda konstant).
- Žádné property testy (zrcadlová symetrie pro náhodné vstupy, horní mez
  rychlosti, determinismus contact modelu).
- ~~Žádný jednotný runner~~ (`tests/run_all.sh`), CI stále chybí.
- Lint: `gdlint` hlásí jen `class-definitions-order` (15×, stylové),
  `gdformat --check` by přeformátoval všech 12 souborů. Buď přijmout
  formátovač, nebo lint vypnout konfigurací — ne nechat šedou zónu.

---

## 1. Roadmapa testování

### T0 — Infrastruktura (½ sezení) — **první krok**

- [x] `tests/run_all.sh`: spustí import + všechny `tests/*_test.gd`, agreguje
      exit code, cesta k Godotu z `$GODOT` env (macOS default z CLAUDE.md).
- [ ] GitHub Actions: `godotengine/godot` 4.7.1 **standard** Linux build
      (GDScript nepotřebuje mono), cache `.godot/`, krok `--import`, pak
      `run_all.sh`. Přesunuto z Fáze 3 sem — bez CI se tuning pass rozbije
      potichu.
- [ ] `gdlintrc` s vypnutým `class-definitions-order` (nebo přeuspořádat
      signály/konstanty) a `gdformat` v CI jako samostatný job. Rozhodnout
      jednou.
- [ ] Sdílený `tests/test_util.gd` (`_expect`, `_expect_near`, `_fly`) —
      dnes 3× copy-paste.

### T1 — Regrese pro nalezené chyby (s opravami B1–B4)

- [x] `gameplay_test`: scénář „touch-down v okně, serve vyprší bez release“
      → `Engine.time_scale == 1.0` v RESULT a v dalším SERVE (B1).
- [x] `contact_test`: kontakt s `ball_vel` — pozdní slabý kontakt zachová
      složku příchozí rychlosti; silný kop ji přebije (B2).
- [x] `gameplay_test`: rozměry brány odpovídají tuningu (B3, brána
      generovaná z `goal.gd`).
- [ ] Pinned výstupy contact modelu pro 5–6 kanonických kopů (golden
      hodnoty jako u physics_test) — chytí nechtěné změny při tuningu D1/D2.

### T2 — Pokrytí mezer

- [x] `swipe_input`: výpočet `(pts, duration, dpi) → {power, curve}` jako
      statická `analyze()`, tabulkové testy v `swipe_test.gd` (oblouk
      doprava/doleva, rovný tah, zrušení, DPI 160 vs 480).
- [ ] `ball_physics`: topspin při odskoku zrychlí dopředu / backspin zbrzdí;
      po slabém odskoku kutálení a `ball_stopped`; spin klesá s `SPIN_DECAY`.
- [ ] `serve_generator`: pro N=500 seedů ověřit, že apex po 1. odskoku ≥
      `IDEAL_KICK_HEIGHT` (nebo že fallback dá ideál uvnitř okna) a že okno
      1.→2. dopad ≥ 0.5 s (dnes 0.66–0.91 s).
- [ ] `game_state` end-to-end scénáře (parametrizovat `gameplay_test`):
      MIMO (offset vpravo bez korekce), VZDUCH (release 200 ms pozdě → druhý
      dopad → MIMO), POZDĚ (bez švihu), NEDOLETĚL (power 0.3).
- [ ] Property testy contact modelu (RNG se seedem, 200 vzorků): zrcadlení
      `offset.x → −offset.x` obrátí `vel.x` a `omega.y`; `|vel| ≤`
      `FOOT_SPEED_MAX·COR_KICK·FOOT_MASS_EFF/BALL_MASS`; `hit == false`
      právě když `|err| ≥ RATING_LATE_EARLY`.

### T3 — Testy pro Fázi 2 (psát spolu s featurami)

- [ ] Tyč/břevno: kolize koule × válec, trajektorie tečující tyč zevnitř =
      gól, zvenku = odraz; symetrie L/R.
- [ ] Verlet síť: pinned body se nehnou, průstřel předá impuls a míč
      zpomalí na `vel *= 0.15`, síť se ustálí do N iterací (headless,
      bez renderu).
- [ ] Heatmapa: bucketizace průsečíků s rovinou brány, rohy vs střed.
- [ ] Performance smoke: 120 Hz fyzika + síť 20×14 při 3 constraint
      iteracích < 2 ms/tick headless (orientační strop pro mobil).
- [ ] Determinismus napříč platformami: stejný seed na macOS (arm64) vs CI
      (x86_64) — porovnat hash trajektorie. Pokud se liší (FMA), replaye /
      daily challenge nesmí spoléhat na bitovou shodu.

---

## 2. Roadmapa vylepšení

### V0 — Opravy — **hotovo**

1. ~~**B1**~~ `_finish_serve` resetuje `Engine.time_scale`; `swipe_input`
   při `enabled = false` během trackingu emituje `swipe_canceled`.
   Regrese: `gameplay_test` (druhá rozehrávka).
2. ~~**B2**~~ `ContactModel.compute_kick(..., ball_vel)`: impuls z relativní
   normálové rychlosti nárt−míč, výstup = příchozí + impuls. Golden hodnoty
   pro `ball_vel = 0` beze změny. Pozn.: pozdní kontakt teď míč **odrazí
   dolů** (nárt má hmotnost, kontakt je vysoko na plášti) — to je
   mechanika „pozdě = do země“, ne průlet. Regrese: `contact_test`.
3. ~~**B3**~~ `goal.gd` staví bránu z tuningu, `pitch.tscn` bez rozměrů.
   Regrese: `gameplay_test` (geometrie).
4. ~~**B4**~~ `SwipeInput.add_point` (min. posun 2 px, strop 256 vzorků
   s decimací) + čistá `analyze()`. Regrese: nový `swipe_test`.

Vedlejší efekt B2 pro tuning pass: příchozí boční rychlost serve míče se
teď propíše do kopu (gól v gameplay_testu se posunul z x=0.00 na 0.32 m).
Hráč tím dostává reálnou zpětnou vazbu „míč přilétal zboku“, ale je to
další proměnná, kterou D1/D2 tuning musí vzít v úvahu.

### V1 — Tuning pass jádra (D1–D2, ½ dne hraní + čísla)

- Rozhodnout tvar timing křivky: buď širší `TIMING_SIGMA` (~80–90 ms) tak,
  aby GOOD dávalo ~70 % síly, nebo podlaha kvality (např. 0.35) v pásmu
  LATE/EARLY. Cíl: LATE kop **doletí nízko a spadne** (topspin), ne že se
  nestane. Ověřit tabulkou jako v sondě D1 a pinnout v `contact_test`.
- Elevace středového zásahu: přidat `swing_dir` složku do směru
  (`vel = n·… + swing_dir·LIFT_SHARE·…`) nebo nechat a posunout default
  offset kamery/overlaye tak, aby „střed“ overlaye byl fyzicky mírně pod
  střed míče. Rozhodnout hraním.
- Přehodnotit `CURVE_SPIN` vs `SPIN_TRANSFER` (D5): faleš z oblouku by
  neměla být silnější než faleš z offsetu bez ztráty síly.
- Každou změnu konstanty zapsat do tuning.gd s datem/důvodem v komentáři.

### V2 — Fáze 2 podle VOLLEY_PLAN.md §7 (doporučené pořadí)

1. **Tyč / břevno kolize** (nejlevnější, největší dopad na výsledky; navazuje
   na B3). Výsledek „TYČ“ + shake.
2. **Flight kamera** (spring arm, damping, FOV kick) — bez ní se let nedá
   číst; dnes statická kamera za hráčem.
3. **Foot swing** (D3): vizuální nárt + zpoždění kontaktu `SWING_DURATION`
   od release; timing se měří k okamžiku kontaktu, ne puštění. Kalibrovat
   `TIMING_SIGMA` znovu.
4. **Verlet síť** (§6) — až po tyčích; headless test z T3.
5. **Heatmapa + streak + session stats** — čistá data v `session_stats.gd`
   (testovatelné), render zvlášť.
6. **Zvuk + puls míče v okně** (§5.2) — naučitelný rytmus bez UI.
7. Low-poly stadion, světla, DOF — až nakonec, hlídat Mobile renderer
   budget.

### V3 — Fáze 3 mobil

- Touch latence: kalibrační offset `TOUCH_LATENCY_COMP` v tuningu, měřit
  na reálném zařízení (tap-test scéna, která vypíše rozptyl).
- DPI normalizace síly ověřit na 2–3 zařízeních (D-test ze T2 dává jen
  konzistenci, ne pocit).
- Godot `physics/common/physics_interpolation` zapnout (120 Hz fyzika vs
  60/90/120 Hz displej — bez interpolace míč cuká na 90 Hz panelech).
- Gradle build + AAB, adaptive ikony, verze/kód z jednoho místa.
- Profiling na střední třídě: cíl 60 fps se sítí; fallback 16×10 z plánu.

### V4 — Údržba / tech-debt

- Sjednotit Godot verzi v dokumentaci (plán říká 4.3+, projekt 4.7).
- CLAUDE.md: příkazy přes `$GODOT` env, ne natvrdo macOS cesta, aby
  fungovaly v CI a v cloud sezeních.
- `debug_trail.gd` a debug kopy 1/2/3 za `OS.is_debug_build()` nebo
  feature flag, aby nešly do release.
- Input map akce místo `KEY_1`/`KEY_A` (umožní touch debug tlačítka).

---

## 3. Doporučené pořadí práce

1. T0 (runner + CI + lint rozhodnutí) — půl sezení, hned.
2. V0 opravy B1–B4 + T1 regrese — jedno sezení.
3. V1 tuning pass s pinned golden hodnotami — hraní + čísla.
4. T2 pokrytí mezer průběžně při V2.
5. V2 v uvedeném pořadí, každá feature s testem z T3.
6. V3/V4 před prvním buildem na zařízení.

Definition of Done pro každý krok: CI zelené, změna konstant zdůvodněná
v `tuning.gd`, nový kód s headless testem tam, kde nezávisí na renderu.
