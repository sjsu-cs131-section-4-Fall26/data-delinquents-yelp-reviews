# top_words.awk -v star=<1..5> -v limit=<max rows> -- word counts in reviews with that star rating.
# Lowercases, strips non-letters, skips short words and a small stoplist. Deterministic: first <limit> rows.
BEGIN {
  FS = OFS = "\t"
  split("this that with have they were from there their about would which when what your just very been will them than then also into only some more here after even much because", sw, " ")
  for (i in sw) stop[sw[i]] = 1
}
NR == 1 { next }
$4 + 0 != star { next }
++seen > limit { exit }
{
  t = tolower($8); gsub(/[^a-z' ]/, " ", t)
  m = split(t, w, " ")
  for (i = 1; i <= m; i++) if (length(w[i]) > 3 && !(w[i] in stop)) c[w[i]]++
}
END { for (x in c) printf "%s\t%d\n", x, c[x] }
