# filter.awk -- quality filter on normalized TSV (9 cols). Header kept via NR==1.
BEGIN { FS = OFS = "\t" }
function valid_date(date, parts, year, month, day, maxday) {
  if (date !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/)
    return 0

  split(date, parts, "-")
  year = parts[1] + 0
  month = parts[2] + 0
  day = parts[3] + 0

  if (year < 1 || month < 1 || month > 12 || day < 1)
    return 0

  maxday = 31

  if (month == 4 || month == 6 || month == 9 || month == 11)
    maxday = 30
  else if (month == 2) {
    maxday = 28
    if (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0))
      maxday = 29
  }

  return day <= maxday
}
NR == 1 { print; next }
{
  total++
  if ($1 !~ /[^[:space:]]/ ||
    $2 !~ /[^[:space:]]/ ||
    $3 !~ /[^[:space:]]/) {
    bad_key++
    next
  }
  if (NF != 9)                          { bad_nf++;    next }
  if ($4 !~ /^[1-5](\.0)?$/) { bad_stars++; next }  
  if ($5 !~ /^[0-9]+$/ || $6 !~ /^[0-9]+$/ || $7 !~ /^[0-9]+$/) { bad_votes++; next }
  if (!valid_date(substr($9, 1, 10))) { bad_date++; next } 
  if ($8 == "")                         { empty_text++; next }
  print; kept++
}
END {
  printf "total=%d kept=%d bad_key=%d bad_nf=%d bad_stars=%d bad_votes=%d bad_date=%d empty_text=%d\n",
    total, kept, bad_key, bad_nf, bad_stars, bad_votes, bad_date, empty_text > "/dev/stderr"
}
