.PHONY: get format format-check analyze test check devices dev emulators preview seed-data web publish-rules

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
	npm --prefix test/rules exec -- firebase --config test/rules/firebase.json emulators:exec --only firestore --project kws-hypomnema "npm --prefix test/rules test"

check: format-check analyze test

devices:
	flutter devices

dev:
	flutter run$(if $(DEVICE), -d $(DEVICE))

emulators:
	firebase emulators:start --only auth,firestore --import seed-data

publish-rules:
	firebase deploy --only firestore:rules --project kws-hypomnema

preview:
	flutter widget-preview start

seed-data:
	firebase emulators:export ./seed-data --force

web:
	flutter build web
