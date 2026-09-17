#!/usr/bin/env bash
set -e

# Proxy defaults (override with MC_PROXY_HOST / MC_PROXY_PORT).
MC_PROXY_HOST="${MC_PROXY_HOST:-127.0.0.1}"
MC_PROXY_PORT="${MC_PROXY_PORT:-17890}"

proxy_on() {
	local proxy_url="http://${MC_PROXY_HOST}:${MC_PROXY_PORT}"
	export http_proxy="$proxy_url" https_proxy="$proxy_url" all_proxy="$proxy_url"
	export HTTP_PROXY="$proxy_url" HTTPS_PROXY="$proxy_url" ALL_PROXY="$proxy_url"
	export no_proxy="127.0.0.1,localhost"
	export NO_PROXY="127.0.0.1,localhost"

	echo -e "\033[32m[√] Proxy enabled on ${MC_PROXY_HOST}:${MC_PROXY_PORT} \033[0m"
}

proxy_off() {
	unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
	unset no_proxy NO_PROXY

	echo -e "\033[31m[×] Proxy disabled on ${MC_PROXY_HOST}:${MC_PROXY_PORT} \033[0m"
}

get_project_root() {
	local dir
	local git_root

	git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
	if [[ -n "$git_root" && -f "$git_root/.project-root" ]]; then
		echo "$git_root"
		return 0
	fi

	dir="$(pwd)"
	while [[ "$dir" != "/" ]]; do
		if [[ -f "$dir/.project-root" ]]; then
			echo "$dir"
			return 0
		fi
		dir="$(dirname "$dir")"
	done

	echo "Error: Could not find project root (missing .project-root marker)" >&2
	return 1
}

# Opt-in proxy on source: export MC_ENABLE_PROXY=1 before sourcing.
if [[ "${MC_ENABLE_PROXY:-}" == "1" ]]; then
	proxy_on
fi
