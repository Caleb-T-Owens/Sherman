#!/usr/bin/env python3
import json
import os
from pathlib import Path

print("I'm trouble")

def as_bool(value: str, default: bool) -> bool:
    if value is None:
        return default
    value = value.strip().lower()
    if value in {"1", "true", "yes", "on"}:
        return True
    if value in {"0", "false", "no", "off"}:
        return False
    return default


def require_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise SystemExit(f"Missing required environment variable: {name}")
    return value


server_name = os.getenv("MATRIX_SERVER_NAME", "matrix.localhost").strip()
postgres_password = require_env("POSTGRES_PASSWORD")
form_secret = require_env("SYNAPSE_FORM_SECRET")
macaroon_secret_key = require_env("SYNAPSE_MACAROON_SECRET_KEY")

public_baseurl = os.getenv("SYNAPSE_PUBLIC_BASEURL", f"https://{server_name}/").strip()
if not public_baseurl.endswith("/"):
    public_baseurl = f"{public_baseurl}/"

report_stats = as_bool(os.getenv("SYNAPSE_REPORT_STATS"), False)
enable_registration = as_bool(os.getenv("SYNAPSE_ENABLE_REGISTRATION"), True)
enable_registration_without_verification = as_bool(
    os.getenv("SYNAPSE_ENABLE_REGISTRATION_WITHOUT_VERIFICATION"), True
)
registration_requires_token = as_bool(os.getenv("SYNAPSE_REGISTRATION_REQUIRES_TOKEN"), False)

signing_key_path = f"/data/{server_name}.signing.key"

config = f"""server_name: {json.dumps(server_name)}
public_baseurl: {json.dumps(public_baseurl)}
pid_file: /data/homeserver.pid
report_stats: {'true' if report_stats else 'false'}
serve_server_wellknown: true

listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation]

database:
  name: psycopg2
  args:
    user: synapse
    password: {json.dumps(postgres_password)}
    database: synapse
    host: db
    cp_min: 5
    cp_max: 10

enable_registration: {'true' if enable_registration else 'false'}
enable_registration_without_verification: {'true' if enable_registration_without_verification else 'false'}
registration_requires_token: {'true' if registration_requires_token else 'false'}

macaroon_secret_key: {json.dumps(macaroon_secret_key)}
form_secret: {json.dumps(form_secret)}

media_store_path: /data/media_store
signing_key_path: {json.dumps(signing_key_path)}

trusted_key_servers:
  - server_name: "matrix.org"
"""

Path("/data").mkdir(parents=True, exist_ok=True)
Path("/data/homeserver.yaml").write_text(config, encoding="utf-8")
print("Rendered /data/homeserver.yaml")
