# Öffentliches GHCR-Image für dieses Projekt

Damit andere Nutzer das mitgelieferte Pelican-Egg ohne GitHub-Credentials verwenden können, muss das GHCR-Container-Package öffentlich sein.

## Maintainer: einmalige Einrichtung

1. Führe mindestens einmal den Workflow **Build & publish Pelican Yolk** aus.
2. Öffne auf GitHub dein Profil bzw. die Organisation und das Package `azerothcore-pelican-aio`.
3. Öffne **Package settings**.
4. Unter **Danger Zone → Change visibility** wähle **Public**.
5. Bestätige die Änderung.

Bei einem öffentlichen GHCR-Container können Nutzer das Image anonym ziehen. Für das Standardprojekt lautet die Image-URI:

```text
ghcr.io/nazgile94/azerothcore-pelican-aio:latest
```

Test auf einem beliebigen Docker-Host:

```bash
docker pull ghcr.io/nazgile94/azerothcore-pelican-aio:latest
```

Dafür sollte bei einem öffentlichen Package kein `docker login` nötig sein.

## Forks

Der Workflow eines Forks veröffentlicht automatisch unter dem jeweiligen GitHub-Owner:

```text
ghcr.io/<owner>/azerothcore-pelican-aio:latest
```

Der Workflow erzeugt außerdem ein Egg-Artefakt, das bereits diese URI verwendet. Soll das Image eines Forks ebenfalls öffentlich von anderen genutzt werden, muss auch dort das Package einmalig auf **Public** gestellt werden.

## Hinweis zur Sichtbarkeit

GitHub behandelt die Sichtbarkeit von Container-Packages separat. Ein öffentliches GitHub-Repository bedeutet daher nicht automatisch, dass ein neu erzeugtes GHCR-Package sofort öffentlich ist. Prüfe die Package-Einstellung nach dem ersten Publish.
