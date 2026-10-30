# length_vs_stars.awk -- bucket reviews by word count; avg stars and useful votes per bucket.
BEGIN { FS = OFS = "\t" }
NR == 1 { next }
{
  w = split($8, t, " ")
  b = (w <= 25) ? "1_short(<=25)" : (w <= 75) ? "2_medium(26-75)" : (w <= 150) ? "3_long(76-150)" : "4_very_long(>150)"
  n[b]++; s[b] += $4; u[b] += $5
}
END { for (b in n) printf "%s\t%d\t%.3f\t%.3f\n", b, n[b], s[b]/n[b], u[b]/n[b] }
