.PHONY: get format format-check analyze test check devices run emulators

get:
	flutter pub get

format:
	dart format .

format-check:
	dart format --output=none --set-exit-if-changed .

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
