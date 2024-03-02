# duckdb-extension-template-zig

A Zig & Nix toolkit template for building extensions against multiple versions of DuckDB
using Zig, C or C++.

## Usage

```shell
> nix develop -c $SHELL
> duckdb -unsigned
D LOAD 'zig-out/lib/quack.duckdb_extension';
D FROM duckdb_extensions();
┌──────────────────┬─────────┬───────────┬──────────────┬────────────────────────────────────────────────────────────────────────────────────┬───────────────────┐
│  extension_name  │ loaded  │ installed │ install_path │                                    description                                     │      aliases      │
│     varchar      │ boolean │  boolean  │   varchar    │                                      varchar                                       │     varchar[]     │
├──────────────────┼─────────┼───────────┼──────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────┤
│ arrow            │ false   │ false     │              │ A zero-copy data integration between Apache Arrow and DuckDB                       │ []                │
...
│ quack            │ true    │           │              │                                                                                    │ []                │
...
│ visualizer       │ true    │           │              │ Creates an HTML-based visualization of the query plan                              │ []                │
├──────────────────┴─────────┴───────────┴──────────────┴────────────────────────────────────────────────────────────────────────────────────┴───────────────────┤
│ 24 rows                                                                                                                                              6 columns │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
D FROM duckdb_extensions();
> WHERE function_name ILIKE '%quack%';
┌───────────────┬─────────────┬───────────────┬───────────────┬─────────────┬─────────────┬───┬─────────┬──────────────────┬──────────────────┬──────────┬──────────────┬─────────┐
│ database_name │ schema_name │ function_name │ function_type │ description │ return_type │ … │ varargs │ macro_definition │ has_side_effects │ internal │ function_oid │ example │
│    varchar    │   varchar   │    varchar    │    varchar    │   varchar   │   varchar   │   │ varchar │     varchar      │     boolean      │ boolean  │    int64     │ varchar │
├───────────────┼─────────────┼───────────────┼───────────────┼─────────────┼─────────────┼───┼─────────┼──────────────────┼──────────────────┼──────────┼──────────────┼─────────┤
│ system        │ main        │ quack         │ scalar        │             │ VARCHAR     │ … │         │                  │ false            │ true     │         1473 │         │
├───────────────┴─────────────┴───────────────┴───────────────┴─────────────┴─────────────┴───┴─────────┴──────────────────┴──────────────────┴──────────┴──────────────┴─────────┤
│ 1 rows                                                                                                                                                    14 columns (12 shown) │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
D SELECT quack('howdy');
┌────────────────┐
│ quack('howdy') │
│    varchar     │
├────────────────┤
│ Quack howdy 🐥 │
└────────────────┘
```

## How it Works

DuckDB is a fast in-process analytical database written in C++ that can be extended by
creating and loading a dynamically linked library using the [extension API](https://duckdb.org/docs/extensions/overview.html). 
Typically extensions are written in C++ using the officially supported [extension template](https://github.com/duckdb/extension-template).

But you're one of the cool kids and want to write your extension in Zig! Fortunately the [Zig build system](https://ziglang.org/learn/build-system/)
ships with a Zig, C & C++ compiler. 

### 1. Create a project directory initialized with the multi flake template

The Nix environment generated by the `flake.nix` [template](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/templates/multi/flake.nix)
provides a self contained Linux & MacOS development toolchain:

- Clang (16.0.6)
- libcxx headers (16.0.6)
- Zig `master` (0.12.0-dev.3124+9e402704e)
- Multiple `duckdb` CLI & `libduckdb` versions linked to the same versions of `libc` & `libcxx` as the Zig compiler (v0.10.0, v0.9.2 & main)

```shell
> mkdir myextension && cd myextension
> nix flake init -t github:rupurt/duckdb-extension-template-zig#multi
> nix develop .#v0-9-2 -c $SHELL
```

### 2. Implement 2 extension loader functions

When a DuckDB extension is loaded via `LOAD 'myextension.duckdb_extension';` it requires [2 symbols](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/src/root.zig#L7C1-L13C2)
to be defined (`myextension_version` & `myextension_init`). The value returned from `*_init` must
match the version of DuckDB loading the extension.

We create a [simple header file](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/src/include/bridge.h) to
expose these 2 symbols in our built extension.

### 3. Create a C++ bridge that calls `DuckDB::ExtensionUtil`

The extension utils helper plugs into DuckDB internals such as:

- scalar functions
- table functions
- custom catalogs
- much more...

The example in this repository [registers a simple scalar function](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/src/bridge.cpp#L26) called `quack`

### 4. Configure the Zig build system and compile the extension

The Zig build system is configured in [build.zig](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/build.zig).

- We'll need to add a [shared library](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/build.zig#L12) exposing
the DuckDB extension hooks defined in `root.zig`.
- Add the [include](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/build.zig#L16) path for the
[C header file](https://github.com/rupurt/duckdb-extension-template-zig/tree/main/src/include) exposing these hooks.
- Don't forget the [C++ bridge](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/build.zig#L19)
- By convention DuckDB extensions use the file suffix `.duckdb_extension`. Zig writes the dynamic library using 
the format `libmyextension.[so|dylib|dll]`. Add a custom install step to use the DuckDB naming convention
for the [extension filename](https://github.com/rupurt/duckdb-extension-template-zig/blob/main/build.zig#L29).

## Limitations

Currently this template can only build extensions that don't rely on [third_party](https://github.com/duckdb/duckdb/tree/main/third_party)
libraries included in the DuckDB repository. I have opened a [Github issue](https://github.com/NixOS/nixpkgs/issues/292855) to include
those libraries in the `nixpkgs` derivation.

## Development

This repository assumes you have Nix [installed](https://determinate.systems/posts/determinate-nix-installer)

```shell
> nix develop .#main -c $SHELL
> nix develop .#v0-9-2 -c $SHELL
> nix develop .#v0-10-0 -c $SHELL
```

```shell
> make
```

Run the Zig test suite

```shell
> make test
```

Delete artifacts from previous builds

```shell
> make clean
```

Build extension binary with Zig

```shell
> make build
```

Run `duckdb` cli allowing `-unsigned` extensions

```shell
> make run
```

## License

`duckdb-extension-template-zig` is released under the [MIT license](./LICENSE)
