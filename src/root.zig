const std = @import("std");

pub const c_bridge = @cImport({
    @cInclude("bridge.h");
});

export fn quack_version() [*c][*c]u8 {
    return @ptrCast(@alignCast(@constCast(c_bridge.extension_version())));
}

export fn quack_init(db: *anyopaque) void {
    c_bridge.extension_init(db);
}
