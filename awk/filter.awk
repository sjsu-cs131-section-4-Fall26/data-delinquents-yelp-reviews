# filter.awk -- quality filter on normalized TSV (9 cols). Header kept via NR==1.
BEGIN { FS = OFS = "\t" }
NR == 1 { print; next }
{
  total++
  if ($1 == "")                         { bad_key++;   next }
  if (NF != 9)                          { bad_nf++;    next }
  if ($4 + 0 < 1 || $4 + 0 > 5)         { bad_stars++; next }
  if ($5 !~ /^[0-9]+$/ || $6 !~ /^[0-9]+$/ || $7 !~ /^[0-9]+$/) { bad_votes++; next }
  if ($9 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)       { bad_date++;  next }
  if ($8 == "")                         { empty_text++; next }
  print; kept++
}
END {
  printf "total=%d kept=%d bad_key=%d bad_nf=%d bad_stars=%d bad_votes=%d bad_date=%d empty_text=%d\n",
    total, kept, bad_key, bad_nf, bad_stars, bad_votes, bad_date, empty_text > "/dev/stderr"
}
