# Star3D SuperFX launch hang — tracking (no Jira instance connected; paste into Jira when available)

## [BUG] SuperFX GSU launch hangs the CPU on cycle-accurate emulators (bsnes/Mesen2)

**Priority:** High
**Component:** snes-examples/superfx/Star3D
**Labels:** superfx, gsu, emulator-compat, needs-investigation

### Summary
The Star3D SuperFX demo launches the GSU coprocessor correctly and the GSU program runs to
completion correctly, but the 65816 CPU never resumes execution after triggering the launch
(writing `R15`, `$301E`/`$301F`) on cycle-accurate emulators (bsnes, Mesen2). The same ROM
works on lenient cores (Snes9x, "snesfox").

### Steps to reproduce
1. Build `snes-examples/superfx/Star3D` (`make` with `PVSNESLIB_HOME` set).
2. Run `star3d.sfc` in bsnes or Mesen2.
3. Screen stays black forever (`INIDISP` forced-blank bit never clears).
4. Run the same ROM in Snes9x or "snesfox" — cube renders correctly.

### Confirmed facts (verified via debugger, not inferred)
- GSU register addresses/bit layout are correct — Mesen2's own GSU register viewer matches
  our writes exactly (`PBR=$3034`, `SCBR=$3038`, `SCMR=$303A`, `R15=$301E/$301F`, `SFR=$3030`).
- The GSU program's logic is correct — hand-verified `FMULT` output (`R0=$FFE5`) against the
  actual math for vertex 0.
- The GSU chip does receive the launch and does execute — confirmed twice via GSU debugger,
  mid-program with correct register state and at `STOP` with correct end-of-program `R15`.
- The GSU reliably reaches `STOP`, both executing directly from ROM (`PBR=1`) and after being
  copied to and executed from its own RAM bank (`PBR=$71`).
- `crt0_snes.asm` leaves `DB=$7E` after its `.bss` clear and never restores it before calling
  `main()` — confirmed real (separate) bug, fixed by using `.l` (explicit long) addressing for
  all raw register pokes.
- Removing the `R15` high-byte write entirely (GSU never launched) → program runs to
  completion normally (garbage/uninitialized screen content, since GSU never populated the
  framebuffer, but screen turns on and everything else works).
- Writing `R15` (tested: single 16-bit indirect store, split 8-bit stores, `.l`-addressed
  16-bit store) → CPU appears to stop advancing immediately after the write, **while**
  separately confirmed the CPU is not globally frozen (NMI continues firing, cycle counter
  climbs into the hundreds of millions in the same session).

### Ruled out
- Compiler codegen bug (hand-written assembly reproduces the identical hang).
- `DB`/bank addressing bug (fixed independently; no change in outcome).
- ROM-vs-RAM execution location for the GSU program (both hang identically).
- The `SFR` (`$3030`) bit-5 completion poll (removed entirely in favor of a fixed-delay wait;
  no change in outcome — CPU never reaches even the trivial instruction *immediately
  following* the `R15` write, before any poll runs).
- Header `CARTRIDGETYPE`/`SRAMSIZE` (retail Star Fox ROM header uses `$13`/`$00`, same as ours).
- GSU 512-byte code-cache window exhaustion (added periodic `CACHE` resets; no change; also
  being re-tested with a minimal 2-instruction GSU program).

### Open contradiction (root cause not yet identified)
CPU is demonstrably still executing (NMI fires normally, cycle counter advances) elsewhere in
the session, yet the `main()` flow's own progress marker never advances past "about to
launch" / "just launched." This has not been reconciled with a direct single-step trace
through the exact instruction gap — that trace is the next required evidence, not another
speculative fix.

### Reference material
- `/Users/malik.a.alayli/Documents/github/public/snesfox/Star3D/build.py` — original raw
  hand-assembled reference (works on lenient emulators).
- `/Users/malik.a.alayli/Documents/github/public/pvsneslib/snes-examples/superfx/StarFox/SG_extracted/`
  — real Star Fox retail disassembly; `ramstuff.asm` (`runmario_l`, `do_3d_display_l`) shows the
  retail GSU-launch pattern (`PBR` via `.l`, explicit `DB=0` via `phb`/`plb`, `R15` via single
  16-bit `STX`), `bootnmi.asm` (`startsfx_l`) shows retail boot-time hardware init.

---

## [TASK] Confirm whether a single 16-bit `R15` store (vs. split stores) resolves the hang

**Priority:** High
**Linked to:** the bug ticket above (blocks it)
**Labels:** superfx, gsu, investigation
**Status:** in progress — build ready, awaiting emulator test result

### Context
Real Star Fox writes `R15` (`$301E`) as a single 16-bit `STX` (one bus transaction for both
bytes). Our code has tried this several ways. Current build combines a `.l`-addressed 16-bit
store with a minimal `cache`/`stop` GSU program (isolating two variables at once, so result
needs a follow-up regardless of outcome).

### Steps
1. Test minimal `cache`/`stop` GSU program + single 16-bit `R15` store together (build is
   ready as of this writing: `star3d.sfc`, freshly rebuilt, no errors).
2. If it works: re-test with the *full* cube-rendering GSU program restored (backup at
   `/tmp/star3d_gsu.s.full_backup`) to confirm the single-write fix alone is sufficient without
   the reduced program.
3. If it still hangs: single-step the regular 65816 debugger through the exact instructions
   between the pre-launch and post-launch checkpoints to determine whether `PC` is parked on a
   specific instruction (real stall) or `SP` has reset to `$01FF` (indicating a silent reboot
   rather than a hang).

### Success criteria
`screenState` reaches `6` and the rendered cube is visible on bsnes and Mesen2.
