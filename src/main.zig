const std = @import("std");

fn xor(string: []const u8, key: []const u8) ![]const u8 {
    if (key.len == 0) return string;

    const allocator = std.heap.page_allocator;
    var buf = try allocator.alloc(u8, string.len);

    for (string, 0..) |char, i| {
        buf[i] = char ^ @as(u8, @intCast(i)) ^ key[i % key.len];
        if (i < 0) buf[i] = buf[i - 1] ^ buf[i];
    }

    return buf;
}

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(
            buffer,
            '\n',
    )) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

fn security_check() ![]const u8 {
    const stdin = std.io.getStdIn();
    var buffer: [30]u8 = undefined;

    return try nextLine(stdin.reader(), &buffer) orelse "";
}

fn help() void {
    std.debug.print("\x1b[32mHELP SCREEN HERE\x1b[0m\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    if (args.len == 0) {
        help(); return;
    } else if (std.mem.eql(u8, args[1], "help")) {
        help(); return;
    }

    const base = "/home/.passwords/";
    const path = try allocator.alloc(u8, base.len + args[1].len);
    std.mem.copyForwards(u8, path[0..base.len], base);
    std.mem.copyForwards(u8, path[base.len..args[1].len], args[1]);

    var file = try std.fs.cwd().openFile(path, .{.mode = .read_write});
    defer file.close();

    try file.seekTo(0);
    const content = try file.readToEndAlloc(allocator, 10000);
    
    if (content.len == 0) {
        std.debug.print("\x1b[31mNo passwords to display.\x1b[0m\nDo you want to create a safe with this name? (y/n) ", .{});
    } else {
        std.debug.print("Enter the password for {s}: ", .{args[1]});
        const password = try security_check();
        std.debug.print("\x1b[H\x1b[J\x1b[32mHere is the content: \x1b[0m\n\n{any}\n\n", .{try xor(content, password)});
    }
}
