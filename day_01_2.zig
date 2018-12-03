const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const os = std.os;

pub fn main() !void {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    var input01 = try get_file_contents(allocator, "input_01.txt");
    defer allocator.free(input01);

    debug.warn("01-2: {}\n", first_visited_twice(input01));
}

fn first_visited_twice(input: []const u8) !i32 {
    var sum: i32 = 0;
    var index: usize = 0;

    const visited_magnitude: usize = 1000000;
    const visited_size: usize = (visited_magnitude * 2) + 1;
    // [ -visited_magnitude, ..., -3, -2, -1, 0, 1, 2, 3, ..., visited_magnitude ]
    var visited = []bool{false} ** visited_size;

    //debug.warn("{} ", sum);
    while (true) {
        var visited_index = @intCast(usize, @intCast(i32, visited_magnitude) + sum);
        debug.assert(visited_index >= 0);
        if (visited[visited_index] == true) {
            return sum;
        } else {
            visited[visited_index] = true;
        }

        var e = index;
        while (input[e] != '\n') {
            e += 1;
        }
        debug.assert('\n' == input[e]);

        var num = try fmt.parseInt(i32, input[index..e], 10);
        sum += num;
        //debug.warn("+ {}\n", num);
        //debug.warn("{} ", sum);
        index = (e + 1) % input.len;
    }
    debug.warn("\n---\n");
    return sum;
}

test "first_visited_twice" {
    debug.assert(0 == try first_visited_twice("+1\n-1\n"));
    debug.assert(10 == try first_visited_twice("+3\n+3\n+4\n-2\n-4\n"));
    debug.assert(5 == try first_visited_twice("-6\n+3\n+8\n+5\n-6\n"));
    debug.assert(14 == try first_visited_twice("+7\n+7\n-2\n-7\n-4\n"));
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
