const std = @import("std");
var stdin = std.fs.File.reader(std.fs.File.stdin(), &.{}).interface;
const allocator = std.heap.page_allocator;

fn nextLine() ![]const u8 {
    const line = try stdin.allocRemaining(allocator, std.Io.Limit.unlimited);
    return std.mem.trimRight(u8, line, "\r");
}

fn help() void {
    std.debug.print("\x1b[32mHELP SCREEN HERE\x1b[0m\n", .{});
}

fn passdir() !void {
    const dir = try nextLine();
    _ = dir;
}

fn open(database: []u8) !void {
    _ = database;
}

fn delete() void {}

const options = enum {
    help,
    passdir,
    open,
    delete,
};

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    if (args.len == 0) {
        help();
    }

    const passfile = try std.fs.cwd().openFile(
        "passwords",
        .{ .mode = .read_write },
    );

    const database = passfile.readToEndAlloc(std.heap.page_allocator, 100000) catch |err| {
        try passdir();
        return err;
    };
    if (database.len == 0) {
        try passdir();
        try open(database);
    }

    switch (std.meta.stringToEnum(options, args[1]) orelse .help) {
        .help => help(),
        .passdir => {},
        .open => try open(database),
        .delete => {},
    }
}
