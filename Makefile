IMAGE ?= ghcr.io/replace-me/azerothcore-pelican-aio:latest

.PHONY: egg validate package

egg:
	python3 scripts/generate_egg.py --image "$(IMAGE)" --output egg-azerothcore-aio.json

validate: egg
	python3 scripts/validate_repo.py

package: validate
	rm -f azerothcore-pelican-aio.zip
	zip -r azerothcore-pelican-aio.zip . -x '.git/*' -x 'azerothcore-pelican-aio.zip'
