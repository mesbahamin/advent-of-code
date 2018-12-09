const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const os = std.os;

const test_nums = []u32 { 2, 3, 0, 3, 10, 11, 12, 1, 1, 0, 1, 99, 2, 1, 1, 2, };
const debug_logging: bool = false;

pub fn main() !void {
    var allocator = &std.heap.DirectAllocator.init().allocator;

    var nums: []u32 = undefined;
    {
        const input = try getFileContents(allocator, "input_08.txt");
        defer allocator.free(input);
        nums = try getNums(allocator, input);
    }
    defer allocator.free(nums);

    const result = try sumMetadataEntries(allocator, nums);
    debug.warn("07-1: {}\n", result);
}

fn sumMetadataEntries(allocator: *mem.Allocator, nums: []const u32) !u32 {
    const Task = enum {
        GetHeader,
        Descend,
        Ascend,
        GetMetadata,
    };
    var nodes = std.ArrayList(Node).init(allocator);
    defer nodes.deinit();

    // I need to manage this myself since I've decided not to use recursion
    var node_stack = std.ArrayList(Node).init(allocator);
    defer node_stack.deinit();

    var root_node = Node {
        .index = 0,
        .num_children = 1,
        .num_metadata = 0,
        .num_children_found = 0,
        .metadata_entries = undefined,
    };

    var parent_node: Node = root_node;
    var current_node: Node = undefined;
    var task: Task = Task.GetHeader;
    var num_index: usize = 0;

    while (num_index < nums.len) {
        logDebug("# {}\n", @tagName(task));
        switch (task) {
            Task.GetHeader => {
                var node_index = num_index;
                var num_children = nums[num_index];
                num_index += 1;
                var num_metadata = nums[num_index];
                num_index += 1;
                current_node = try Node.init(node_index, num_children, num_metadata, allocator);
                if (current_node.num_children != 0) {
                    task = Task.Descend;
                } else {
                    task = Task.GetMetadata;
                }
            },
            Task.Descend => {
                try node_stack.append(parent_node);
                parent_node = current_node;
                task = Task.GetHeader;
            },
            Task.Ascend => {
                current_node = parent_node;
                parent_node = node_stack.pop();
                task = Task.GetMetadata;
            },
            Task.GetMetadata => {
                for (current_node.metadata_entries) |*e| {
                    e.* = nums[num_index];
                    num_index += 1;
                }

                try nodes.append(current_node);
                parent_node.num_children_found += 1;

                if (parent_node.num_children_found < parent_node.num_children) {
                    task = Task.GetHeader;
                } else if (parent_node.num_children_found == parent_node.num_children) {
                    task = Task.Ascend;
                } else {
                    unreachable;
                }
            },
            else => unreachable,
        }
        logDebug("P");
        parent_node.print();
        logDebug("C");
        current_node.print();
    }
    // Why did I put myself through that?

    var metadata_sum: u32 = 0;
    for (nodes.toSlice()) |n| {
        for (n.metadata_entries) |e| {
            metadata_sum += e;
        }
    }

    return metadata_sum;
}

test "sum metadata entries" {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    debug.assert(138 == try sumMetadataEntries(allocator, test_nums));
}

const Node = struct {
    index: usize,
    num_children: u32,
    num_metadata: u32,
    num_children_found: u32,
    metadata_entries: []u32,

    pub fn init(i: usize, nc: u32, nm: u32, allocator: *mem.Allocator) !Node {
        var me_buf = try allocator.alloc(u32, nm);
        return Node {
            .index = i,
            .num_children = nc,
            .num_metadata = nm,
            .num_children_found = 0,
            .metadata_entries = me_buf,
        };
    }

    pub fn deinit(self: Node, allocator: *mem.Allocator) void {
        allocator.free(self.metadata_entries);
    }

    pub fn print(self: Node) void {
        logDebug("[{}]: ({}/{}, {}) | ", self.index, self.num_children_found, self.num_children, self.num_metadata);
        for (self.metadata_entries) |e| {
            logDebug("{} ", e);
        }
        logDebug("\n");
    }
};

fn getNums(allocator: *mem.Allocator, buf: []const u8) ![]u32 {
    var it = mem.split(buf, []u8 { ' ', '\n', });
    var nodes = std.ArrayList(u32).init(allocator);
    while (it.next()) |token| {
        var num = try fmt.parseInt(u32, token, 10);
        try nodes.append(num);
    }
    return nodes.toSlice();
}

test "get nums" {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    const test_buf = "2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2";
    debug.assert(mem.eql(u32, test_nums, try getNums(allocator, test_buf)));
}

fn getFileContents(allocator: *mem.Allocator, file_name: []const u8) ![]u8 {
    var file = try os.File.openRead(file_name);
    defer file.close();

    const file_size = try file.getEndPos();

    var file_in_stream = io.FileInStream.init(file);
    var buf_stream = io.BufferedInStream(io.FileInStream.Error).init(&file_in_stream.stream);
    const st = &buf_stream.stream;
    return try st.readAllAlloc(allocator, 2 * file_size);
}

fn logDebug(comptime format_str: []const u8, args: ...) void {
    if (debug_logging) {
        debug.warn(format_str, args);
    }
}
