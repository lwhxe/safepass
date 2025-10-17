const std = @import("std");
var w_buffer: [1024]u8 = undefined;
var writer: std.fs.File.Writer = std.fs.File.stdout().writer(&w_buffer);
const stdout: *std.Io.Writer = &writer.interface;

var r_buffer: [1024]u8 = undefined;
var reader: std.fs.File.Reader = std.fs.File.stdin().reader(&r_buffer);
const stdin: *std.Io.Reader = &reader.interface;

const AES = std.crypto.aead.aes_gcm.Aes128Gcm;
var tag: [AES.tag_length]u8 = undefined;
var nonce: [AES.nonce_length]u8 = [_]u8{0x00} ** AES.nonce_length;

const allocator = std.heap.page_allocator;

fn open(database: []u8) void {
    try stdout.print("password: ", .{});
    try stdout.flush();

    const encryption_key = try stdin.peekDelimiterExclusive('\n');
    var plaintext: [10000]u8 = undefined;
    try AES.decrypt(&plaintext, database, tag, "", nonce, encryption_key);

    try stdout.print("\nPLAINTEXT:\n\n{s}\n\n", .{plaintext});
}

fn create() !void {
    try stdout.print("Creating passwords file...\n", .{});
    try stdout.flush();
    // Create passwords file
    _ = try std.fs.cwd().createFile("passwords", .{});
}

pub fn main() !void {
    try stdout.print("Welcome to safepass!\n", .{});
    try stdout.flush();

    const passfile = while (true) {
        break std.fs.cwd().openFile(
            "passwords",
            .{ .mode = .read_write }
        ) catch {
            try stdout.print("Do you want to create a new passwords file? (y/n)", .{});
            try stdout.flush();

            const ans = try stdin.takeDelimiterExclusive('\n');

            if (ans[0] == 'y') {
                try create();
            }
            try stdout.print("Done.\n", .{});
            try stdout.flush();

            // discard remaining stdin

            continue;
        };
    };

    const database = passfile.readToEndAlloc(std.heap.page_allocator, 10000) catch |err| {
        return err;
    };
    if (database.len == 0) {
        std.debug.print("An empty passwords file has been found!\n", .{});
    }
}
