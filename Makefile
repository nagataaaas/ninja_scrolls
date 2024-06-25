.PHONY: setup lint
UNAME := $(shell uname)

lint:
	dart run import_sorter:main

setup:
	flutter clean
	flutter pub get

profile-sksl:
	flutter run --profile --cache-sksl --purge-persistent-cache

build: setup
ifeq ($(UNAME), Darwin)
	flutter build ios
else
	flutter build appbundle
	flutter build apk
endif