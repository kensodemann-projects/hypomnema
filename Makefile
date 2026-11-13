.PHONY: get format format-check analyze test check devices run emulators preview seed-data web

get:
	flutter pub get

format:
	dart format lib test

format-check:
	dart format --output=none --set-exit-if-changed lib test

analyze:
	flutter analyze

test:
	flutter test

check: format-check analyze test

devices:
	flutter devices

run:
	flutter run$(if $(DEVICE), -d $(DEVICE))

emulators:
	firebase emulators:start --only auth,firestore

preview:
	flutter widget-preview start

seed-data:
	firebase emulators:export ./seed-data --force

web:
	flutter build web
