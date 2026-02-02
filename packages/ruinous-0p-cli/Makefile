.PHONY: build test lint clean

BINARY_NAME=0p
BUILD_DIR=.

build:
	go build -ldflags "-X forge.meskill.farm/ruinous/0p-cli/cmd.Version=dev -X forge.meskill.farm/ruinous/0p-cli/cmd.Commit=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) -X forge.meskill.farm/ruinous/0p-cli/cmd.Date=$$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o $(BUILD_DIR)/$(BINARY_NAME) .

test:
	go test -v ./...

lint:
	golangci-lint run

clean:
	rm -f $(BUILD_DIR)/$(BINARY_NAME)

deps:
	go mod download
	go mod tidy
