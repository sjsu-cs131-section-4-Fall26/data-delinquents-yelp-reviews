# normalize.sed -- one Yelp review JSON line -> one TSV line (run with sed -E)
# Out columns: review_id user_id business_id stars useful funny cool text date
# Relies on Yelp's fixed key order; each rule peels one JSON key into a TAB.

# 1. strip the opening  {"review_id":"
s/^\{"review_id":"//
# 2. quoted-string keys -> TAB
s/","user_id":"/\t/
s/","business_id":"/\t/
# 3. numeric keys (unquoted values) -> TAB
s/","stars":/\t/
s/,"useful":/\t/
s/,"funny":/\t/
s/,"cool":/\t/
# 4. text key, then date key at end of line (date moves to last column)
s/,"text":"/\t/
s/","date":"([^"]*)"\}$/\t\1/
# 5. text cleanup: JSON escapes for newline/return/tab -> single space
s/\\[nrt]/ /g
# 6. unescape quotes and backslashes; normalize curly quotes to straight
s/\\"/'/g
s/\\\\/\//g
# 7. trim whitespace around delimiters and line ends; collapse repeated spaces
s/[ ]*\t[ ]*/\t/g
s/^[ ]+|[ ]+$//g
s/[ ]{2,}/ /g
# 8. NA normalization for empty/null numeric fields
s/\tnull(\t|$)/\tNA\1/g
# normalize curly quotes (literal alternation: byte-safe under LC_ALL=C)
s/‘|’|“|”/'/g
# normalize curly quotes (literal alternation: byte-safe under LC_ALL=C)
s/‘|’|“|”/'/g
