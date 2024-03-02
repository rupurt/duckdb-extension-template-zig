all: test build

.PHONY: test
test:
	zig build test
test.summary:
	zig build test --summary all

build: build.fast
build.fast:
	zig build -Doptimize=ReleaseFast
build.small:
	zig build -Doptimize=ReleaseSmall
build.safe:
	zig build -Doptimize=ReleaseSafe

clean:
	rm -rf zig-*

run:
	duckdb -unsigned
