#!/usr/bin/env bash

set -euo pipefail
: "${SERVICE_ROLE:?SERVICE_ROLE is required}"

case "${SERVICE_ROLE}" in
    server|client) ;;
    *) echo "Invalid SERVICE_ROLE: ${SERVICE_ROLE}" >&2; exit 1 ;;
esac

udp2raw_args=()
udpspeeder_args=()

tmp_port=${SERVICE_TMP_PORT:-50000}

case "${SERVICE_ROLE}" in
    server)
            udp2raw_args+=("-s" "-l" "${SERVICE_LISTEN_IP}:${SERVICE_LISTEN_PORT}" "-r" "127.0.0.1:${tmp_port}")
            udpspeeder_args+=("-s" "-l" "127.0.0.1:${tmp_port}" "-r" "${SERVICE_REMOTE_IP}:${SERVICE_REMOTE_PORT}")
            ;;
    client)
            udp2raw_args+=("-l" "-l" "127.0.0.1:${tmp_port}" "-r" "${SERVICE_REMOTE_IP}:${SERVICE_REMOTE_PORT}")
            udpspeeder_args+=("-l" "-l" "${SERVICE_LISTEN_IP}:${SERVICE_LISTEN_PORT}" "-r" "127.0.0.1:${tmp_port}")
            ;;
    *) echo "Invalid SERVICE_ROLE: ${SERVICE_ROLE}" >&2; exit 1 ;;
esac

while IFS='=' read -r key value; do
    case "$key" in
        UDP2RAW_*)
            name="${key#UDP2RAW_}"
            name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
            if [ -n "${name:-}" ]
            then
                udp2raw_args+=("--${name}")
                if [ -n "${value:-}" ]
                then
                    udp2raw_args+=("${value}")
                fi
            fi
            ;;
        UDPSPEEDER_*)
            name="${key#UDPSPEEDER_}"
            name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
            if [ -n "${name:-}" ]
            then
                udpspeeder_args+=("--${name}")
                if [ -n "${value:-}" ]
                then
                    udpspeeder_args+=("${value}")
                fi
            fi
            ;;
    esac
done < <(env)

echo "udp2raw ${udp2raw_args[@]}"
echo "speederv2 ${udpspeeder_args[@]}"

udp2raw "${udp2raw_args[@]}" &
udp2raw_pid=$!
speederv2 "${udpspeeder_args[@]}" &
udpspeeder_pid=$!

trap 'kill ${udp2raw_pid} ${udpspeeder_pid} 2>/dev/null' SIGTERM SIGINT

wait -n

kill ${udp2raw_pid} ${udpspeeder_pid} 2>/dev/null
wait


