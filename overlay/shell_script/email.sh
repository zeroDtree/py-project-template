#!/usr/bin/env bash

# @help-begin
# Send an experiment-completion email via Python smtplib (no mutt required).
#
# Usage:
#   bash shell_script/email.sh [exit_code]
#
# Env: credentials come from shell_script/env_email.sh (gitignored).
# Copy env_email.sh.example to env_email.sh and fill in SMTP settings.
#
# If no options are passed, the default behavior is equivalent to:
#   bash shell_script/email.sh 0
# @help-end

# @help-options-begin
#   -h, --help              show help
# @help-options-end

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
	awk '/^# @help-begin$/{f=1; next} /^# @help-end$/{f=0} f' "$0"
	printf '%s\n' '#' 'Options:' '#'
	awk '/^# @help-options-begin$/{f=1; next} /^# @help-options-end$/{f=0} f' "$0"
	exit 0
}

case "${1:-}" in
	-h|--help) usage ;;
esac

cd "$PROJECT_ROOT"

ENV_EMAIL="$SCRIPT_DIR/env_email.sh"
if [[ ! -f "$ENV_EMAIL" ]]; then
	echo "Error: missing $ENV_EMAIL" >&2
	echo "Copy shell_script/env_email.sh.example to shell_script/env_email.sh and fill in SMTP settings." >&2
	exit 1
fi

# shellcheck source=env_email.sh
source "$ENV_EMAIL"

if [[ -z "${FROM_EMAIL:-}" || -z "${FROM_EMAIL_HOST:-}" || -z "${FROM_SMTP_PASSWORD:-}" || -z "${TO_EMAIL:-}" ]]; then
	echo "Error: SMTP settings in shell_script/env_email.sh are incomplete." >&2
	exit 1
fi

EXIT_CODE="${1:-0}"
export EXIT_CODE
export FROM_NAME="${EMAIL_FROM_NAME:-$(whoami)}"
export EXPERIMENT_NAME
EXPERIMENT_NAME="$(basename "$(pwd)")"
export MACHINE
MACHINE="$(hostname)"
export MACHINE_IP
MACHINE_IP="$(hostname -i 2>/dev/null | awk '{print $1}' || true)"
export FINISHED_AT
FINISHED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
export PWD_PATH
PWD_PATH="$(pwd)"
export USER_NAME
USER_NAME="$(whoami)"

PYTHON_BIN="${PROJECT_ROOT}/.venv/bin/python"
if [[ ! -x "${PYTHON_BIN}" ]]; then
	PYTHON_BIN="python3"
fi

echo "Sending experiment completion notification..."
if "${PYTHON_BIN}" - <<'PY'
import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

exit_code = int(os.environ.get("EXIT_CODE", "0"))
ok = exit_code == 0
status = "Success" if ok else "Failed"
status_color = "#27ae60" if ok else "#e74c3c"
status_emoji = "OK" if ok else "FAIL"

from_email = os.environ["FROM_EMAIL"]
from_name = os.environ["FROM_NAME"]
to_email = os.environ["TO_EMAIL"]
smtp_host = os.environ["FROM_EMAIL_HOST"]
smtp_port = int(os.environ["FROM_EMAIL_PORT"])
smtp_password = os.environ["FROM_SMTP_PASSWORD"]

experiment_name = os.environ["EXPERIMENT_NAME"]
machine = os.environ["MACHINE"]
machine_ip = os.environ.get("MACHINE_IP", "")
finished_at = os.environ["FINISHED_AT"]
pwd_path = os.environ["PWD_PATH"]
user_name = os.environ["USER_NAME"]

subject = f"{machine} experiment done: {experiment_name}"

html_body = f"""\
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.4; color: #333; max-width: 500px; margin: 0 auto;">
    <div style="text-align: center; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0; font-size: 24px;">{status_emoji} Experiment finished</h1>
    </div>
    <div style="padding: 20px; background: #f8f9fa; border-radius: 0 0 8px 8px;">
        <div style="background: white; padding: 15px; border-radius: 5px; margin-bottom: 15px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <h3 style="margin-top: 0; color: #2c3e50;">Experiment</h3>
            <p><strong>Name:</strong> {experiment_name}</p>
            <p><strong>Status:</strong> <span style="color: {status_color}; font-weight: bold;">{status}</span></p>
            <p><strong>Finished at:</strong> {finished_at}</p>
            <p><strong>Exit code:</strong> {exit_code}</p>
        </div>
        <div style="background: white; padding: 15px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <h3 style="margin-top: 0; color: #2c3e50;">Host</h3>
            <p><strong>Working dir:</strong> {pwd_path}</p>
            <p><strong>Hostname:</strong> {machine}</p>
            <p><strong>User:</strong> {user_name}</p>
            <p><strong>IP:</strong> {machine_ip}</p>
        </div>
    </div>
</body>
</html>
"""

msg = MIMEMultipart("alternative")
msg["Subject"] = subject
msg["From"] = f"{from_name} <{from_email}>"
msg["To"] = to_email
msg.attach(MIMEText(html_body, "html", "utf-8"))

# Corporate SMTP CAs are often missing on HPC images; require TLS but skip CA verify.
context = ssl.create_default_context()
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE
with smtplib.SMTP_SSL(smtp_host, smtp_port, context=context) as server:
    server.login(from_email, smtp_password)
    server.sendmail(from_email, [to_email], msg.as_string())

print("Notification sent successfully.")
PY
then
	:
else
	echo "Notification send failed." >&2
	exit 1
fi
