# Using a private GHCR image with Pelican Wings

The GHCR package can stay private. Create a GitHub **Personal Access Token (classic)** with at least `read:packages` for an account that can read the package.

On the **Wings node**, add this below the existing `docker:` section in `/etc/pelican/config.yml`:

```yaml
docker:
  registries:
    ghcr.io:
      username: "YOUR_GITHUB_USER"
      password: "ghp_YOUR_READ_ONLY_TOKEN"
```

Do not create a second top-level `docker:` key. Restart Wings afterwards:

```bash
sudo systemctl restart wings
sudo systemctl status wings
```

Node-side test:

```bash
echo 'TOKEN' | docker login ghcr.io -u YOUR_GITHUB_USER --password-stdin
docker pull ghcr.io/youruser/azerothcore-pelican-aio:latest
```

Never commit the token to the egg, repository, README, or server variables.
