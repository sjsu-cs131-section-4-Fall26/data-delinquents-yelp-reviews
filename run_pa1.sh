#!/usr/bin/env bash
# run_pa1.sh -- Part 1: UNIX large-file exploration of Yelp review JSON-lines
# Usage:   bash run_pa1.sh <path/to/yelp_academic_dataset_review.json>
# Assumes: one JSON object per line, Yelp key order. Fields before "text" are pulled with
#          cut -d'"' (review_id=f4 user_id=f8 business_id=f12); numeric fields with grep -o | cut.
# Outputs: data/samples/, out/, logs/pa1_run.log   Only PA1-allowed tools are used.
set -euo pipefail
export LC_ALL=C
{ [ $# -eq 1 ] && [ -r "$1" ]; } || { echo "usage: bash run_pa1.sh <INPUT> (must be readable)" >&2; exit 1; }
IN=$1
mkdir -p data/samples out logs
LOG=logs/pa1_run.log

{
echo "== A) data card facts =="
ls -lh "$IN"
echo "lines: $(wc -l < "$IN")"
echo "-- peek (first record, 400 chars) --"
head -n 1 "$IN" | cut -c1-400

echo "== B) reproducible 1000-record sample =="
if command -v shuf >/dev/null 2>&1; then
  shuf --random-source=<(yes) -n 1000 "$IN" > data/samples/review_sample_1k.json
else
  # macOS has no shuf: deterministic reservoir sample of exactly 1000 lines
  awk -v n=1000 'BEGIN{srand(42)} NR<=n{r[NR]=$0;next} {j=int(rand()*NR)+1; if(j<=n) r[j]=$0} END{for(i=1;i<=n;i++) print r[i]}' "$IN" > data/samples/review_sample_1k.json
fi
echo "sample lines: $(wc -l < data/samples/review_sample_1k.json)"

echo "== C) frequency tables =="
# freq 1: star rating (numeric field -> grep -o then cut)
grep -o '"stars":[0-9.]*' "$IN" | cut -d: -f2 | sort -n | uniq -c | tee out/freq_stars.txt
# freq 2: review year (date is the last key)
grep -o '"date":"[0-9]\{4\}' "$IN" | cut -d'"' -f4 | sort | uniq -c | tee out/freq_year.txt
# freq 3: useful votes
grep -o '"useful":[0-9]*' "$IN" | cut -d: -f2 | sort -n | uniq -c | sort -nr | tee out/freq_useful.txt | awk 'NR<=10'

# Top-N: 25 most-reviewed businesses / 25 most active users (fields before "text" are safe to cut)
cut -d'"' -f12 "$IN" | sort | uniq -c | sort -nr | awk 'NR<=25' | tee out/topN_businesses.txt
cut -d'"' -f8 "$IN" | sort | uniq -c | sort -nr | awk 'NR<=25' > out/topN_users.txt

echo "== skinny table: review_id, business_id =="
cut -d'"' -f4,12 "$IN" | tr '"' '\t' > out/skinny_review_business.tsv
wc -l out/skinny_review_business.tsv

echo "== grep -i / grep -v demo =="
echo "mentions of 'rude' (case-insens): $(grep -ic 'rude' "$IN")"
grep -i 'rude' "$IN" | grep -v '"stars":5' | cut -d'"' -f4 | awk 'NR<=5' > out/grep_demo_rude_not5star.txt

echo "== redirection: stdout vs stderr kept separate, then >> append =="
grep -c '"stars":1.0' "$IN" > out/results.txt 2> out/errors.txt
echo "1-star reviews counted on $(date +%F)" >> out/results.txt
cat out/results.txt

echo "== optional join: business review counts + 5-star counts =="
cut -d'"' -f12 "$IN" | sort | uniq -c | awk '{print $2"\t"$1}' | sort -t$'\t' -k1,1 > out/biz_total.tsv
grep '"stars":5.0' "$IN" | cut -d'"' -f12 | sort | uniq -c | awk '{print $2"\t"$1}' | sort -t$'\t' -k1,1 > out/biz_5star.tsv
join -t$'\t' out/biz_total.tsv out/biz_5star.tsv | sort -t$'\t' -k2,2nr | awk 'NR<=25' > out/biz_total_vs_5star.tsv
} 2>&1 | tee "$LOG"
echo "done; see out/ and $LOG" >&2
