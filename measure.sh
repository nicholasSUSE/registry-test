# AT AWS EC2 INSTANCE
docker logs <container_id_or_name> > logs

# DOWNLOAD LOGS LOCALLY
sudo scp -i ./aws/certs/id_rsa $INSTANCE_DNS:logs ./logs


# CHECK NUM OF REQUESTS
REQ_NUM=$(grep 'GET /v2/' logs | wc -l)


# CHECK AVERAGE REQUEST SIZE
REQ_AVG=$(cat logs |
awk '
/GET \/v2\// {
    request=$0
    next
}
/http\.response\.written/ {
    split($0, a, "http.response.written=")
    print request " " a[2]
}' |
awk '{sum += $NF; count++} END {if (count > 0) print "Sum:", sum, "Average:", sum/count}')