# count_by.awk -v key=<col> [-v year=1] -- per-group: reviews, avg stars, total useful, pct 5-star
# year=1 groups by the 4-digit year of the date column instead of a raw column.
BEGIN { FS = OFS = "\t" }
NR == 1 { next }
{
  k = year ? substr($9, 1, 4) : $key
  n[k]++; s[k] += $4; u[k] += $5; if ($4 == 5) f[k]++
}
END { for (k in n) printf "%s\t%d\t%.3f\t%d\t%.1f\n", k, n[k], s[k]/n[k], u[k], 100*f[k]/n[k] }
