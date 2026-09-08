# VOLLEY_PLAN.md — Simulátor kopání do míče (volej)

> Godot 4.3+ (Mobile renderer), GDScript, cíl: Android + iOS.
> Jádro hry: **contact model** — kde a kdy nárt potká míč. Vše ostatní (trajektorie, faleš, síť) z toho vyplývá deterministicky.

---

## 1. Vize a herní smyčka

Míč přiskáče k hráči (každý odskok jiný) → hráč jedním swipem určí kontaktní bod, faleš, sílu a timing → freeze-frame ukáže kontakt → kamera letí za míčem → gól / tyč / mimo → statistiky → další míč.

**Pocit, o který jde:** volej má okno. Pozdě je pozdě — míč klesá, nárt ho trefí shora, topspin do země. Perfektní timing = čistý kontakt = míč letí.

---

## 2. Architektura

```
volley/
├── project.godot
├── scenes/
│   ├── main.tscn                 # root: game state machine
│   ├── pitch.tscn                # hřiště, brána, světla
│   ├── ball.tscn                 # RigidBody3D-like custom body
│   ├── foot.tscn                 # kinematický nárt (kapsle) + švihová animace
│   ├── net.tscn                  # verlet cloth síť
│   └── ui/
│       ├── hud.tscn              # rychlost, spin, timing rating
│       ├── swipe_overlay.tscn    # zvětšený míč pro input
│       └── heatmap.tscn          # session heatmapa brány
├── scripts/
│   ├── core/
│   │   ├── game_state.gd         # FSM: Serve → Approach → KickWindow → Flight → Result
│   │   ├── ball_physics.gd       # integrace letu (drag + Magnus + bounce)
│   │   ├── contact_model.gd      # ⭐ jádro: nárt × míč → impuls + spin
│   │   ├── foot_swing.gd         # dráha švihu, rychlost nohy v čase
│   │   └── serve_generator.gd    # náhodné nadhozy/odskoky (seedovatelné)
│   ├── input/
│   │   └── swipe_input.gd        # gesto → KickIntent {contact_offset, curve, power, release_time}
│   ├── net/
│   │   └── verlet_net.gd         # cloth sim + impuls při průstřelu
│   ├── ui/
│   │   ├── freeze_frame.gd       # 150 ms zpomalení + zvýraznění kontaktu
│   │   └── stats.gd              # km/h, ot/s, perfect/late/early
│   └── util/
│       └── tuning.gd             # VŠECHNY konstanty na jednom místě (autoload)
├── assets/                       # low-poly modely, materiály, SFX
└── tests/
    └── physics_test.gd           # headless testy trajektorií (GUT framework)
```

**Zásady:**
- Fyzika letu je **vlastní integrace** (nespoléhat na Godot RigidBody3D pro Magnus — Godot ho nemá). Ball je `CharacterBody3D`/custom, integrace v `_physics_process` (semi-implicit Euler, 120 Hz fixed substep).
- `contact_model.gd` je čistá funkce: `(foot_state, ball_state, timing) → (impulse, spin)`. Žádné závislosti na scéně → snadno testovatelné headless.
- Všechny konstanty v `tuning.gd` (autoload singleton) — ladění bez hledání magic numbers.

---

## 3. Fyzikální model

### 3.1 Míč
- Koule: r = 0.11 m, m = 0.43 kg (FIFA size 5)
- Stav: `pos: Vector3, vel: Vector3, omega: Vector3` (spin v rad/s)

### 3.2 Let (ball_physics.gd)
```
F_gravity = m * g                          # g = Vector3(0, -9.81, 0)
F_drag    = -0.5 * RHO * CD * A * |v| * v  # RHO=1.225, CD≈0.25 (turbulentní), A=πr²
F_magnus  = S_COEFF * (omega × v)          # S_COEFF ≈ 0.0021 (ladit!)
spin decay: omega *= exp(-SPIN_DECAY * dt) # SPIN_DECAY ≈ 0.15
```

### 3.3 Odskok (pro přiskákání míče před kopem)
```
v_out.y = -RESTITUTION * v_in.y            # RESTITUTION ≈ 0.62 (tráva)
v_out.xz = v_in.xz * (1 - GROUND_FRICTION) # + přenos spinu do odskoku
```

### 3.4 Kontakt (contact_model.gd) — ⭐ srdce hry
Nárt = kapsle (r_foot ≈ 0.05 m) pohybující se po oblouku švihu rychlostí `v_foot(t)`.

```
input:  contact_offset: Vector2   # kde na míči (od středu, normalizováno -1..1)
        swing_curve: float        # zakřivení swipu -1..1
        power: float              # 0..1 z rychlosti swipu
        timing_error: float       # ms od ideálního okamžiku kontaktu

1. timing_quality = exp(-(timing_error / TIMING_SIGMA)²)   # TIMING_SIGMA ≈ 45 ms
2. v_foot = FOOT_SPEED_MAX * power * timing_quality        # FOOT_SPEED_MAX ≈ 28 m/s
3. normála kontaktu n = normalize(ball_center - contact_point)
4. impulse = m_eff * v_foot * COR_KICK * n                 # COR_KICK ≈ 0.8, m_eff ≈ 0.9*m nohy
5. tangenciální složka:
   d = contact_offset promítnutý do roviny kolmé na švih
   omega += SPIN_TRANSFER * v_foot * (swing_dir × d)       # faleš z offsetu
   omega += CURVE_SPIN * v_foot * swing_curve * up_axis    # faleš ze zakřivení swipu
6. pozdní kontakt (timing_error > 0): kontaktní bod se posouvá NAHORU na míči
   → normála míří dolů dopředu → topspin, nízká trajektorie, "nedoletí"
   posun: contact_offset.y -= LATE_SHIFT * (timing_error / TIMING_WINDOW)
```

Bod 6 je klíčový — mechanicky realizuje "pozdě už je pozdě" bez umělé penalizace.

### 3.5 Timing okno
- Volej: míč po odskoku stoupá → vrchol → klesá. Ideál = lehce za vrcholem (výška ~0.4–0.7 m).
- `perfect`: |error| < 30 ms, `good`: < 70 ms, `late/early`: < 120 ms, jinak `miss` (nárt mine / tečuje).

---

## 4. Ovládání (swipe_input.gd)

Jedno gesto, výstup `KickIntent`:

| Fáze gesta | Mapování |
|---|---|
| Touch-down na overlay míči | `contact_offset` (Vector2 od středu, -1..1) |
| Dráha prstu (fit kvadratické křivky) | `swing_curve` (-1..1) |
| Průměrná rychlost swipu (px/s, normalizace na DPI) | `power` (0..1) |
| Čas puštění prstu vs. ideální kontakt | `timing_error` (ms) |

- Overlay míč: dole uprostřed, průměr ~35 % šířky obrazovky, semi-transparent, kopíruje reálnou rotaci míče (hráč vidí, jak se točí).
- **Assist mode (default ON):** slow-motion 0.6× od touch-down. Pro mode = 1.0×.
- Dead-zone 8 px proti mikrotřesu, min. délka swipu 40 px.

---

## 5. UX / prezentace

1. **Serve:** kamera nízko za hráčem (~1.2 m, FOV 55°), míč přiskáče z náhodného směru (serve_generator: seed → reprodukovatelné pro testy i daily challenge později).
2. **Kick window:** jemný vizuální puls na míči při vstupu do timing okna (naučitelný rytmus, žádný ukazatel — pocit, ne UI).
3. **Freeze-frame 150 ms:** zvýrazněný kontaktní bod na míči i nártu + vektor švihu. Hráč se učí *proč*.
4. **Flight cam:** follow kamera za míčem (spring arm, damping), lehký FOV kick při silném kopu.
5. **Result:** rozvlnění sítě / tyč (SFX + camera shake) / aut. Overlay: `92 km/h · 7.2 ot/s · PERFECT (+12 ms)`.
6. **Session heatmapa** brány (kam střílíš) + streak counter.

---

## 6. Síť (verlet_net.gd)

- Mřížka **20 × 14** bodů, verlet integrace, 3 constraint iterace / frame.
- Horní řada + boky pinned (rám brány).
- Průstřel: najdi nejbližší bod k průsečíku trajektorie s rovinou brány → impuls `ball_vel * NET_IMPULSE_TRANSFER` s gaussovským falloff na sousedy (σ ≈ 2 buňky).
- Míč v síti: zbrzdit `vel *= 0.15`, nechat vypadnout gravitací.
- Render: `ImmediateMesh` / `ArrayMesh` update, wireframe + jemný unlit materiál.

---

## 7. Fáze implementace

### Fáze 0 — Skeleton (1–2 sezení)
- [x] Godot projekt, Mobile renderer, portrait orientace, fixed physics 120 Hz
- [x] `tuning.gd` autoload se všemi konstantami z §3
- [x] Hřiště + brána (CSG placeholder), statická kamera
- [x] `ball_physics.gd`: let s drag + Magnus, odskoky; debug trail (line renderer)
- [x] Headless test: srovnat dolet s referencí (kop 25 m/s, 35° → ~24 m bez spinu)
      *Pozn.: s konstantami z §3 (CD=0.25) vychází dolet ~38.9 m — testy jedou
      proti nezávislé Python referenci stejného modelu, viz tests/physics_test.gd.*
- **DoD:** míč letí věrohodně, faleš zatáčí, trajektorie deterministická při stejném seedu

### Fáze 1 — Contact model + input (jádro hry)
- [x] `swipe_input.gd` → `KickIntent`
- [x] `contact_model.gd` čistá funkce + tabulkové testy (offset vpravo → letí
      doleva a Magnusem se vrací doprava atd.; GUT zatím odloženo — vlastní
      SceneTree harness stačí, viz tests/)
- [x] `serve_generator.gd`: nadhozy s odskokem, timing okno (ideál z
      pre-simulace deterministické trajektorie)
- [x] Late-contact shift (§3.4 bod 6)
      *Pozn.: znaménko ve vzorci §3.4/6 opraveno na `+=` — text "posouvá
      NAHORU" je záměr, `-=` byl překlep. Osa spinu v §3.4/5 implementována
      fyzikálně jako `u × t` (z τ = r × F), tvar `swing_dir × d` měl pro tuhle
      geometrii obrácenou orientaci.*
- [x] Freeze-frame + základní HUD (km/h, spin, rating)
- **DoD:** hratelná smyčka serve→kick→result, "pozdě = nedoletí" funguje mechanicky
      ✓ (tests/contact_test.gd: pozdní kontakt = nižší dráha, topspin, slabší
      zásah; tests/gameplay_test.gd: end-to-end serve→kop→GÓL)

### Fáze 2 — Síť, prezentace, pocit
- [ ] `verlet_net.gd` + impuls, tyč/břevno kolize (SFX + shake)
- [ ] Flight kamera (spring arm), FOV kick, slow-mo assist
- [ ] Heatmapa, streak, session stats
- [ ] Low-poly stadium, lighting, DOF na míč (Mobile renderer budget!)
- [ ] Tuning pass: 30 min hraní, ladit `tuning.gd`
- **DoD:** vypadá a zní jako hra, chce se dát "ještě jeden kop"

### Fáze 3 — Mobil + release
- [ ] Android export (AAB, Gradle), iOS export (Xcode projekt, Mac Mini M2)
- [ ] Touch input na reálném zařízení: DPI normalizace, latence, dead-zones
- [ ] Performance: 60 fps na střední třídě (profiler, síť ↓ na 16×10 pokud třeba)
- [ ] godot-ci GitHub Actions pipeline (analogicky k Flutter pipelines)
- **DoD:** build na obou platformách, stabilních 60 fps

### Fáze 4 — Gólman (později)
- Reaktivní agent: reakční zpoždění 180–250 ms po kontaktu, predikce průsečíku trajektorie s rovinou brány + šum, dosah skoku omezen → rohy zůstávají odměnou za přesnost.

---

## 8. Testovací strategie

- **GUT** (Godot Unit Test) headless: contact_model (tabulkové případy offset/curve/timing → očekávaný směr spinu a kvadrant brány), trajektorie (dolet, výška vrcholu ±5 %).
- Seedovaný serve_generator → deterministické replaye pro regresní testy tuningu.
- Debug overlay (`F3`): vektory sil, kontaktní bod, timing error — nechat i v release za flagem.

## 9. Rizika

| Riziko | Mitigace |
|---|---|
| Magnus koeficient "nesedí" pocitově | S_COEFF ladit vizuálně, ne fyzikálně přesně — hra > simulace |
| Swipe timing na mobilu (touch latence ~50–80 ms) | kalibrační offset v nastavení + širší TIMING_SIGMA na mobilu |
| Cloth výkon na slabých telefonech | mřížka 16×10 fallback, update 30 Hz s interpolací |
| Godot IAP pluginy syrovější než Flutter | monetizace až po Fázi 3, žádná závislost v core |

---

*Handoff pro Claude Code: začni Fází 0, `tuning.gd` vytvoř jako první — všechny konstanty z §3 tam. Komentáře v kódu česky, identifikátory anglicky.*
