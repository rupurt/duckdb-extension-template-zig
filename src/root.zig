const std = @import("std");

// Import the bridge header file. Zig can parse and call C directly!
pub const c_bridge = @cImport({
    @cInclude("bridge.h");
});

// Given our extension will build an artifact called `quack.duckdb_extension` define 2 symbols
// that DuckDB will call after it loads the extension with `dlopen`.

export fn quack_version() [*c][*c]u8 {
    return @ptrCast(@alignCast(@constCast(c_bridge.extension_version())));
}

export fn quack_init(db: *anyopaque) void {
    c_bridge.extension_init(db);
}
