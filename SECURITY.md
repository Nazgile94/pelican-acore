# Security notes

- Do not commit GitHub PATs, registry credentials, database dumps, or generated `.secrets/` files.
- Keep `MYSQL_REMOTE_ACCESS=0` unless remote database access is actually required.
- If MySQL is exposed, restrict the allocation/host firewall to trusted source addresses.
- Prefer `ACORE_DB_PASSWORD=auto` for the internal database credential.
- Review third-party AzerothCore modules before adding them; modules are compiled into the server and run with the same container permissions as the core.
