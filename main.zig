const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const os = std.os;

pub fn main() !void {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    var input = try get_file_contents(allocator, "input_01.txt");
    defer allocator.free(input);

    debug.warn("01-1: {}\n", total_sum(input));
}

fn total_sum(input: []const u8) !i32 {
    var sum: i32 = 0;
    var index: usize = 0;
    while (index < input.len) {
        var e = index;
        while (input[e] != '\n') {
            e += 1;
        }
        debug.assert('\n' == input[e]);

        var num = try fmt.parseInt(i32, input[index..e], 10);
        sum += num;
        index = e + 1;
    }
    return sum;
}

test "total_sum" {
    const s: []const u8 = "-2\n-3\n+4\n-15\n-15\n+18\n-7\n+11\n-16\n-134\n+200\n";
    debug.assert(41 == try total_sum(s));
}

fn get_file_contents(allocator: *mem.Allocator, file_name: []const u8) ![]u8 {
    var file = try os.File.openRead(file_name);
    defer file.close();

    const file_size = try file.getEndPos();

    var file_in_stream = io.FileInStream.init(file);
    var buf_stream = io.BufferedInStream(io.FileInStream.Error).init(&file_in_stream.stream);
    const st = &buf_stream.stream;
    return try st.readAllAlloc(allocator, 2 * file_size);
}
