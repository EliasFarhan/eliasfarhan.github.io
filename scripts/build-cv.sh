#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
site_dir="${project_dir}/_site"
port="${CV_PORT:-4173}"

find_chromium() {
  local candidate
  for candidate in "${CHROME_BIN:-}" google-chrome-stable google-chrome chromium chromium-browser; do
    if [[ -n "${candidate}" ]] && command -v "${candidate}" >/dev/null 2>&1; then
      command -v "${candidate}"
      return 0
    fi
  done
  return 1
}

chromium_bin="$(find_chromium || true)"
if [[ -z "${chromium_bin}" ]]; then
  echo "Error: Chromium or Google Chrome is required (or set CHROME_BIN)." >&2
  exit 1
fi

cd "${project_dir}"
bundle exec jekyll build

python3 -m http.server "${port}" --directory "${site_dir}" >/tmp/cv-http-server.log 2>&1 &
server_pid=$!
trap 'kill "${server_pid}" 2>/dev/null || true' EXIT

for _ in {1..30}; do
  if curl --fail --silent "http://127.0.0.1:${port}/cv/" >/dev/null; then
    break
  fi
  sleep 0.2
done

curl --fail --silent "http://127.0.0.1:${port}/cv/" >/dev/null
"${chromium_bin}" \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --no-pdf-header-footer \
  --print-to-pdf="${site_dir}/cv/elias-farhan-cv.pdf" \
  "http://127.0.0.1:${port}/cv/"

test -s "${site_dir}/cv/elias-farhan-cv.pdf"
echo "CV built successfully: ${site_dir}/cv/elias-farhan-cv.pdf"
