OUTPUT = trigtok-deployment
BASE_HREF = /$(OUTPUT)/
# Replace this with your GitHub username
GITHUB_USER = alaninnovates
GITHUB_REPO = https://github.com/$(GITHUB_USER)/$(OUTPUT)
BUILD_VERSION := $(shell grep 'version:' pubspec.yaml | awk '{print $$2}')

# Deploy the Flutter web project to GitHub
deploy:
	@echo "Clean existing repository"
	flutter clean

	@echo "Getting packages..."
	flutter pub get

	# @echo "Generating the web folder..."
	# flutter create . --platform web

	@echo "Building for web..."
	flutter build web --base-href $(BASE_HREF) --release

	@echo "Deploying to git repository"
	cd build/web && \
	git add . && \
	git commit -m "Deploy Version $(BUILD_VERSION)" && \
	git push -f origin main

	@echo "✅ Finished deploy: $(GITHUB_REPO)"

.PHONY: deploy
