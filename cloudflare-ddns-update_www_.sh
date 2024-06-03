#!/bin/bash

# Update a Cloudflare DNS A record with the Public IP of the source machine

# Prerequisites:
# - DNS Record has to be created manually at Cloudflare
# - Cloudflare API Token with edit dns zone permissions https://dash.cloudflare.com/profile/api-tokens
# - curl, jq needs to be installed

# Proxy - uncomment and provide details if using a proxy
#export https_proxy=http://<proxyuser>:<proxypassword>@<proxyip>:<proxyport>

# Cloudflare zone is the zone which holds the record
zone="domain.name"
# dnsrecord is the A record which will be updated
dnsrecord="www.domain.name"

## Cloudflare authentication details
## keep these private
cloudflare_api_token="uTSPbijb-4-5zf6GeWXUsLL3M3-rwmRN0ssu2R1x"


function update_ip() {
  # get the zone id for the requested zone
  zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $cloudflare_api_token" | jq -r '{"result"}[] | .[0] | .id')

  echo "Zoneid for $zone is $zoneid"


  # get the dns record id
  dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dnsrecord" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $cloudflare_api_token" | jq -r '{"result"}[] | .[0] | .id')

  echo "DNSrecordid for $dnsrecord is $dnsrecordid"


  # update the record
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $cloudflare_api_token" \
    --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":true}" | jq
}

function get_ip() {
  # Get the public IP address
  ip=$(curl -s -X GET https://checkip.amazonaws.com)
  dnsip=$(dig $dnsrecord +short @1.1.1.1)

  echo "Public IP is $ip"

  if [[ "$dnsip" == "$ip" ]]; then
    echo "$dnsrecord is currently set to $ip; no changes needed"
    exit
  fi

  update_ip
}

echo ""
echo "-- $(date '+%d/%m/%Y %H:%M:%S') --"
# Run function get_ip
get_ip
