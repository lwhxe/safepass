const std = @import("std");

fn help() void {
    std.debug.print("HELP SCREEN HERE\n", .{});
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    if (args.len == 0) {
        help();
    } else if (std.mem.eql(u8, args[1], "help")) {
        help();
    }


}
