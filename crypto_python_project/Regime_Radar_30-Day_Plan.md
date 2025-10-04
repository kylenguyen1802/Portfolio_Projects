# Regime Radar — TIGHT 30‑Day Plan (EZ Mode 5–6/10)

**Scope:** Crypto only, KMeans (K=3), no HMM, no lead–lag. Optional Allocation‑Lite at the end.  
**Definition of Done (DoD):**
- `processed/hourly.parquet` (cleaned hourly crypto)
- `processed/features_hourly.parquet` (engineered features)
- 3‑state KMeans regimes + state profile table
- Daily regime roll‑up
- Streamlit app with **Dashboard** + **Regimes**
- (Optional) Allocation‑Lite: daily weights + equity curve
- README + executive summary + demo GIF

---

## Week 1 — Data & Features (Days 1–7)

**Day 1 — Repo + env**
- Create folders: `data/{raw,processed}`, `src/{data,features,models,app}`, `notebooks`, `reports`.
- Add `requirements.txt` (from canvas) and `.gitignore` to ignore `data/`.
- Initialize git repo.

**Day 2 — Raw ingest**
- Place Kaggle `cryptocurrency.csv` into `data/raw/`.
- Sanity check columns and missingness.

**Day 3 — Raw → hourly.parquet**
- Use `src/data/load.py` to standardize timestamps (UTC), normalize column names, sort.
- Save to `data/processed/hourly.parquet`.
- Checks: monotonic timestamps per symbol, no duplicate (symbol, timestamp).

**Day 4 — Build features v1**
- Run `src/features/build_features.py` to compute:
  - `ret_1h`, `vol_realized` (24h), `rsi14`, `vol_z`, `hour`, `dow`, `is_us_session`.
- Save to `data/processed/features_hourly.parquet`.

**Day 5 — Focused EDA**
- In `notebooks/01_eda.ipynb`:
  - Histogram of `ret_1h`.
  - Hour‑of‑day volatility heatmap.
  - Missingness/NaN check.
- Write `reports/eda_findings.md` with **5 bullet** takeaways.

**Day 6 — Guardrails**
- Assertions/tests:
  - No NaNs in `ret_1h` after initial lag.
  - `vol_realized ≥ 0`; `rsi14 ∈ [0,100]`.
- `reports/data_dictionary.md` for columns and units.

**Day 7 — Time split**
- Define Train/Val/Test by time (60/20/20).
- Store split boundaries in `reports/split.json`.

---

## Week 2 — Regimes (KMeans only) (Days 8–14)

**Day 8 — Fit KMeans (K=3)**
- Standardize features: `["ret_1h","vol_realized","rsi14","vol_z","hour"]`.
- Fit on **Train** only. Save `models/scaler.pkl` and `models/kmeans_k3.pkl`.

**Day 9 — Label states**
- Compute per‑state profiles on Train:
  - mean hourly return, return std (vol), hit rate.
- Map lowest mean return → **Risk‑Off**, middle → **Choppy**, highest → **Risk‑On**.
- Save `reports/state_profiles_train.csv`.

**Day 10 — Validate**
- Apply model to **Val**; recompute profiles.
- Plot price colored by regime for BTC (sanity check consistency).

**Day 11 — Test pass**
- Predict states on **Test**.
- Export full hourly states to `processed/regimes_hourly.parquet`.
- Note similarities/differences between Val vs Test profiles.

**Day 12 — Daily roll‑up**
- Majority vote per (date, symbol) → `processed/regimes_daily.parquet`.
- Small legend table: date, symbol, daily regime.

**Day 13 — Failure notes**
- Document odd clusters (event spikes/illiquid hours) in `reports/limitations.md`.

**Day 14 — Checkpoint**
- Commit + tag `regimes_v0` and write a short recap.

---

## Week 3 — App & Docs (Days 15–21)

**Day 15 — Streamlit: Dashboard**
- Wire `src/app/streamlit_app.py` to read `features_hourly.parquet`.
- Show last 14d: Close + Hourly Vol for selected symbols.

**Day 16 — Streamlit: Regimes**
- Overlay regime colors on price plot.
- Add state profile table (mean return, vol, win‑rate).

**Day 17 — Controls & caching**
- Multiselect symbols, date window slider.
- Use `@st.cache_data` for Parquet loads.

**Day 18 — README v1**
- Sections: Problem → Data → Methods → Regimes → App → Run → Limitations.
- Include 1–2 screenshots.

**Day 19 — Executive summary (2 pages)**
- TL;DR, main findings, failure cases, next steps.

**Day 20 — Demo GIF**
- Record 20–30s app walkthrough; add to README under `/assets/`.

**Day 21 — QA**
- Fresh clone test; fix missing deps/imports.
- Tag `v0.9`.

---

## Week 4 — Allocation‑Lite (Optional) + Polish (Days 22–30)

**Day 22 — Allocation‑Lite rules**
- Map daily regime → weights, example:
  - Risk‑On: 70% BTC / 30% ETH
  - Choppy: 40% BTC / 20% ETH / 40% cash (or scale exposure to 60%)
  - Risk‑Off: 10% BTC / 5% ETH / 85% cash (or scale exposure to 15%)
- Deterministic, daily rebalancing.

**Day 23 — Equity curve**
- Use daily close returns; compute portfolio vs BTC buy‑and‑hold.
- Metrics: CAGR, Max Drawdown, naive Sharpe.

**Day 24 — App tab (tiny)**
- Add “Allocation” section/tab: weights table + equity curve plot.

**Day 25 — Honesty pass**
- Sensitivity: try K=2 and K=4; confirm results aren’t magical.
- Write leakage statement and rationale for daily execution.

**Day 26 — Final docs**
- Update README + executive summary with Allocation‑Lite results & caveats.

**Day 27 — Content pack**
- Draft TikTok/LinkedIn post: problem, method, one insight, one chart, repo link.

**Day 28 — Code cleanup**
- Move notebook logic into `src/models/regimes_kmeans.py`.
- Add `Makefile` targets: `setup`, `features`, `app`.

**Day 29 — Final QA + tag**
- End‑to‑end run from scratch. Tag `v1.0`.

**Day 30 — Ship & reflect**
- Publish repo; post; write 5 bullets: “What I’d do next” (HMM, lead–lag, costs).

---

## Copy‑paste Commands
```bash
# Build features
python -m src.features.build_features --crypto_csv data/raw/cryptocurrency.csv --out data/processed/features_hourly.parquet

# Run the app
streamlit run src/app/streamlit_app.py
```

## Guardrails Checklist
- [ ] No look‑ahead (features at t use info ≤ t)
- [ ] Time‑based splits (60/20/20)
- [ ] Costs discussed if you add Allocation‑Lite later
- [ ] Document all fills/drops and assumptions
- [ ] Keep signals **daily** for execution; hourly is for detection
