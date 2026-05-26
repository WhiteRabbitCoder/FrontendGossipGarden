-include .env
export

SUPABASE_URL      ?= https://tslrtebdziilekddalcr.supabase.co
SUPABASE_ANON_KEY ?=
GOOGLE_CLIENT_ID  ?=

_DEFINES = \
	--dart-define=SUPABASE_URL=$(SUPABASE_URL) \
	--dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY) \
	--dart-define=GOOGLE_CLIENT_ID=$(GOOGLE_CLIENT_ID)

QA_BACKEND_URL = https://backendgossipgarden-qa.up.railway.app

.PHONY: help dev-web prod-web qa-web dev-android prod-android samsung samsung-qa build-web build-apk analyze test

help:
	@echo "GossipGarden Flutter — comandos disponibles"
	@echo ""
	@echo "  make dev-web       → Chrome,  backend local  (http://localhost:8000)"
	@echo "  make prod-web      → Chrome,  backend Railway (prod)"
	@echo "  make qa-web        → Chrome,  backend Railway (QA)"
	@echo "  make dev-android   → Android, backend local  (10.0.2.2:8000)"
	@echo "  make prod-android  → Android, backend Railway"
	@echo "  make samsung       → Samsung SM S721B, backend Railway (prod)"
	@echo "  make samsung-qa    → Samsung SM S721B, backend Railway (QA)"
	@echo ""
	@echo "  make build-web     → build release web"
	@echo "  make build-apk     → build APK release"
	@echo ""
	@echo "  make analyze       → flutter analyze"
	@echo "  make test          → flutter test --coverage"
	@echo ""
	@echo "  Copia .env.example → .env y rellena SUPABASE_ANON_KEY y GOOGLE_CLIENT_ID"

dev-web:
	flutter run -d chrome $(_DEFINES) --dart-define=BACKEND_TARGET=local

prod-web:
	flutter run -d chrome $(_DEFINES) --dart-define=BACKEND_TARGET=prod

qa-web:
	flutter run -d chrome $(_DEFINES) --dart-define=BACKEND_TARGET=prod --dart-define=BACKEND_DEPLOY_URL=$(QA_BACKEND_URL)

dev-android:
	flutter run -d android $(_DEFINES) --dart-define=BACKEND_TARGET=local

prod-android:
	flutter run -d android $(_DEFINES) --dart-define=BACKEND_TARGET=prod

samsung:
	flutter run -d R5CY508WWYW $(_DEFINES) --dart-define=BACKEND_TARGET=prod

samsung-qa:
	flutter run -d R5CY508WWYW $(_DEFINES) --dart-define=BACKEND_TARGET=prod --dart-define=BACKEND_DEPLOY_URL=$(QA_BACKEND_URL)

build-web:
	flutter build web $(_DEFINES) --dart-define=BACKEND_TARGET=prod

build-apk:
	flutter build apk --release $(_DEFINES) --dart-define=BACKEND_TARGET=prod

analyze:
	flutter analyze

test:
	flutter test --coverage
