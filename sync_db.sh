#!/usr/bin/env bash


set -eo pipefail

: ${DRIVER_VERSION:=main}

src_url=https://raw.githubusercontent.com/NVIDIA/open-gpu-kernel-modules/${DRIVER_VERSION}/README.md
content=$(curl -sSL "${src_url}")
start_line=$(echo "${content}" | nl -b a | grep -e 'Product Name' | awk '{print $1}')


function _ggrep() {
    if command -v ggrep &>/dev/null;then
      ggrep "$@"
    else
      grep "$@"
    fi
}

db=$(cat json_dbs/nvidia_gpu_product_db.json)

while read -r line
do
    if echo "${line}" | _ggrep -qPe '\|[ a-zA-Z0-9-]+\|[ a-zA-Z0-9-]+\|';then
        model=$(echo "${line}" | awk -F'|' '{print $2}' | xargs echo)
        driveID=$(echo "${line}" | awk -F'|' '{print $3}' | xargs echo)
        echo "model [${model}] driveID [${driveID}]"
        db=$(echo "${db}" | jq ". += {\"${driveID}\":\"${model}\"}")
    else
      echo "validate line fail ${line}"
      exit 1
    fi
done < <(echo "${content}" | tail -n  +$((start_line + 2)))

echo "${db}" > json_dbs/nvidia_gpu_product_db.json

echo "update nvidia driver version ${DRIVER_VERSION} success"