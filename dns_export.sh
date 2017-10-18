#!/bin/bash

RS_USER=""
RS_APIKEY=""
RS_REGION=""

catalog=$(curl -s https://identity.api.rackspacecloud.com/v2.0/tokens -d '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username": "'$RS_USER'", "apiKey": "'$RS_APIKEY'"}}}' -X POST -H "Content-type: application/json") && token=$(echo $catalog | jq -r .access.token.id) && dns_ep=$(echo $catalog | jq -r '.access.serviceCatalog[] | select(.type == "rax:dns") | .endpoints[].publicURL')

api_call() {
	curl -s -H "X-Auth-Token: $token" -H "Content-Type: application/json" "$@"
}

for domain_id in $(api_call $dns_ep/domains | jq -r '.domains[] | .id'); do
	job_id=$(api_call $dns_ep/domains/$domain_id/export | jq -r '.jobId')
    job_status="RUNNING"
	while [ job_status == "RUNNING" ]; do
		echo -n "."
		sleep 1
		job_status=$(api_call $dns_ep/status/$job_id | jq -r '.status')
	done
	api_call "$dns_ep/status/$job_id?showDetails=true" | jq -r '.response.contents'
done
