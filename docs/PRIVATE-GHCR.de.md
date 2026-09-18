# Privates GHCR-Image mit Pelican Wings

Das GHCR-Package kann privat bleiben. Erstelle bei GitHub einen **Personal Access Token (classic)** mit mindestens `read:packages` für einen Account, der das Package lesen darf.

Auf dem **Wings-Node** in der vorhandenen `/etc/pelican/config.yml` unter dem bereits vorhandenen `docker:`-Block ergänzen:

```yaml
docker:
  registries:
    ghcr.io:
      username: "DEIN_GITHUB_USER"
      password: "ghp_DEIN_READ_ONLY_TOKEN"
```

Keinen zweiten `docker:`-Rootblock anlegen. Danach Wings neu starten:

```bash
sudo systemctl restart wings
sudo systemctl status wings
```

Zum Testen auf dem Node:

```bash
echo 'TOKEN' | docker login ghcr.io -u DEIN_GITHUB_USER --password-stdin
docker pull ghcr.io/deinuser/azerothcore-pelican-aio:latest
```

Das Token niemals ins Egg, README, Repository oder in Servervariablen committen.
