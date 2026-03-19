.PHONY: setup lint test test-unit test-widget test-integration
UNAME := $(shell uname)

lint:
	dart run import_sorter:main

setup:
	flutter clean
	flutter pub get

profile-sksl:
	flutter run --profile --cache-sksl --purge-persistent-cache

test:
	flutter test

test-unit:
	flutter test test/unit/

test-widget:
	flutter test test/widget/

test-integration:
	flutter test test/integration/

build: setup
ifeq ($(UNAME), Darwin)
	flutter build ios
else
	flutter build appbundle
	flutter build apk
endif