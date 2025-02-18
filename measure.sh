

# Counting requests
grep 'GET /v2/_catalog' logs | wc -l

# Measuring Transferred Byte Size
# sum of all requetsts byte size
grep 'http.response.written' logs | awk -F'=' '{sum+=$2} END {print sum}'

# average size of all requests
grep 'http.response.written' logs | awk -F'=' '{sum+=$2; count++} END {if (count > 0) print sum/count}'

# sum of byte sizes for specific requets
grep 'GET /v2/_catalog' logs | grep 'http.response.written' | awk -F'written=' '{print $2}' | awk '{sum+=$1} END {print sum}'


# average byte size for specific request
grep 'GET /v2/_catalog' logs | grep 'http.response.written' | awk -F'written=' '{print $2}' | awk '{sum+=$1; count++} END {if (count > 0) print sum...
