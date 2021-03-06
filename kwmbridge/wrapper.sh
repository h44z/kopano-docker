#!/bin/sh

set -e
[ "$DEBUG" ] && set -x

if [ -n "${log_level:-}" ]; then
	set -- "$@" --log-level="$log_level"
fi

if [ -n "${oidc_issuer_identifier:-}" ]; then
	set -- "$@" --iss="$oidc_issuer_identifier"
fi

if [ -n "${kwm_server_urls:-}" ]; then
	for url in $kwm_server_urls; do
		set -- "$@" --kwmserver-url="$url"
	done
fi

if [ -n "${ice_interfaces:-}" ]; then
	for ice_if in $ice_interfaces; do
		set -- "$@" --use-ice-if="$ice_if"
	done
fi

if [ -n "${ice_network_types:-}" ]; then
	for ice_network_type in $ice_network_types; do
		set -- "$@" --use-ice-network-type="$ice_network_type"
	done
fi

if [ -n "${ice_udp_port_range:-}" ]; then
	set -- "$@" --use-ice-udp-port-range="$ice_udp_port_range"
fi

if [ -n "${use_nat_1to1_ips:-}" ]; then
	for use_nat_1to1_ip in $use_nat_1to1_ips; do
		set -- "$@" --use-nat-1to1-ip="$use_nat_1to1_ip"
	done
fi

if [ -n "${use_nat_1to1_candidate_type:-}" ]; then
	set -- "$@" --use-nat-1to1-candidate-type="$use_nat_1to1_candidate_type"
fi

if [ "${with_metrics:-}" = "yes" ]; then
	set -- "$@" --with-metrics
fi

if [ "${metrics_listen:-}" ]; then
	set -- "$@" --metrics-listen="$metrics_listen"
fi

if [ "$INSECURE" = "yes" ]; then
	set -- "$@" --insecure
fi

if [ "${AUTOCONFIGURE}" = true ]; then
	if [ "$INSECURE" = "yes" ]; then
		dockerize \
			-skip-tls-verify \
			-wait "$oidc_issuer_identifier"/.well-known/openid-configuration \
			-timeout 360s
	else
		dockerize \
			-wait "$oidc_issuer_identifier"/.well-known/openid-configuration \
			-timeout 360s
	fi

	# services need to be aware of the machine-id
	dockerize \
		-wait file:///etc/machine-id \
		-wait file:///var/lib/dbus/machine-id
fi

exec kwmbridged serve \
	"$@"
