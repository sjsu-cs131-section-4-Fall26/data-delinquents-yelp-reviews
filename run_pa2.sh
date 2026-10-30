#!/usr/bin/env bash
# run_pa2.sh -- Yelp REVIEW dataset: SED normalize -> AWK filter/aggregate -> sorted TSVs
# Usage:   bash run_pa2.sh <path/to/yelp_academic_dataset_review.json>
# Input:   JSON-lines, one review per line, Yelp's fixed key order (no JSON parser needed).
# Outputs: out/*.tsv (relative to CWD, regenerated each run)   Logs: logs/pa2_run.log
# Env:     WORD_LIMIT (default 500000) caps rows scanned per star level for top_words.
set -euo pipefail
export LC_ALL=C   # deterministic sort/awk behavior

die() { echo "ERROR: $*" >&2; exit 1; }
[ $# -eq 1 ] || die "usage: bash run_pa2.sh <INPUT review json>"
INPUT=$1
[ -e "$INPUT" ] || die "input not found: $INPUT"
chmod -R g+rX "$INPUT" 2>/dev/null || true
{ [ -f "$INPUT" ] && [ -r "$INPUT" ]; } || die "input not a readable file: $INPUT"
[ -s "$INPUT" ] || die "input is empty: $INPUT"

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORD_LIMIT=${WORD_LIMIT:-500000}
mkdir -p out logs
LOG=logs/pa2_run.log
: > "$LOG"
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG" >&2; }
TAB=$'\t'
# first_n N : print first N lines of stdin while draining it (safe under pipefail, unlike head)
first_n() { awk -v n="$1" 'NR<=n'; }
# with_header "h1<TAB>h2.." : prepend header to stdin
with_header() { printf '%s\n' "$1"; cat; }

HDR=$'review_id\tuser_id\tbusiness_id\tstars\tuseful\tfunny\tcool\ttext\tdate'

# ---- 1. SED: normalize ---------------------------------------------------------
log "step 1: sed normalize"
{ printf '%s\n' "$HDR"; sed -E -f "$HERE/sed/normalize.sed" "$INPUT"; } > out/normalized.tsv
head -n 4 "$INPUT" | cut -c1-300 > out/sed_before.txt
head -n 4 out/normalized.tsv | cut -c1-300 > out/sed_after.txt

# ---- 2. AWK: quality filter (header kept) -------------------------------------
log "step 2: awk quality filter"
awk -f "$HERE/awk/filter.awk" out/normalized.tsv > out/clean.tsv 2> out/filter_stats.txt
tee -a "$LOG" < out/filter_stats.txt >&2
head -n 101 out/clean.tsv > out/clean_sample.tsv

# ---- 3. AWK: aggregates (all sorted deterministically, ties broken by key) ----
log "step 3: aggregates"
GH=$'reviews\tavg_stars\ttotal_useful\tpct_5star'
awk -v key=4 -f "$HERE/awk/count_by.awk" out/clean.tsv \
  | sort -t"$TAB" -k1,1n | with_header "stars${TAB}${GH}" > out/by_stars.tsv
awk -v year=1 -f "$HERE/awk/count_by.awk" out/clean.tsv \
  | sort -t"$TAB" -k1,1n | with_header "year${TAB}${GH}" > out/by_year.tsv
awk -v key=3 -f "$HERE/awk/count_by.awk" out/clean.tsv \
  | sort -t"$TAB" -k2,2nr -k1,1 | first_n 25 | with_header "business_id${TAB}${GH}" > out/top_businesses.tsv
awk -v key=2 -f "$HERE/awk/count_by.awk" out/clean.tsv \
  | sort -t"$TAB" -k2,2nr -k1,1 | first_n 25 | with_header "user_id${TAB}${GH}" > out/top_reviewers.tsv
awk -f "$HERE/awk/length_vs_stars.awk" out/clean.tsv \
  | sort -t"$TAB" -k1,1 | with_header $'length_bucket\treviews\tavg_stars\tavg_useful' > out/length_vs_stars.tsv
for s in 1 5; do
  awk -v star=$s -v limit="$WORD_LIMIT" -f "$HERE/awk/top_words.awk" out/clean.tsv \
    | sort -t"$TAB" -k2,2nr -k1,1 | first_n 25 | with_header $'word\tcount' > "out/top_words_${s}star.tsv"
done

log "step 4: done"
for f in out/*.tsv; do log "  $f: $(wc -l < "$f") lines"; done
