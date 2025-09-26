const std = @import("std");

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(
            buffer,
            '\n',
    )) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

fn help() void {
    std.debug.print("HELP SCREEN HERE\n", .{});
}

fn passdir() void {
    var buffer: [100]u8 = undefined;
    const dir = try nextLine(std.io.AnyReader, &buffer) orelse "";
    _ = dir;
}

fn open(database: []u8) void {
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
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    if (args.len == 0) {
        help();
    }

    const passfile = try std.fs.cwd().openFile(
        "passwords",
        .{ .mode = .read_write },
    );

    const database = passfile.readToEndAlloc(std.heap.page_allocator, 100000) catch |err| {
        passdir();
        return err;
    };
    if (database.len == 0) {
        passdir();
        open(database);
    }

    switch (std.meta.stringToEnum(options, args[1]) orelse .help) {
        .help => help(),
        .passdir => {},
        .open => open(database),
        .delete => {},
    }
}
