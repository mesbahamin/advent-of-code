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

    const nodes = try deserializeNodes(allocator, nums);
    defer allocator.free(nodes);
    defer {
        // Yes, all this free-ing is rather silly for our purposes. Just
        // trying out defer.
        for (nodes) |n| {
            n.deinit(allocator);
        }
    }

    const result1 = sumAllMetadataEntries(nodes);
    debug.warn("08-1: {}\n", result1);

    const result2 = getRootNodeValue(nodes);
    debug.warn("08-2: {}\n", result2);
}

fn getRootNodeValue(nodes: []Node) u32 {
    var root_node = Node.linearSearch(nodes, 0) orelse unreachable;
    return getNodeValue(nodes, root_node);
}

fn getNodeValue(nodes: []Node, node: Node) u32 {
    var value: u32 = 0;

    if (node.num_children == 0) {
        value = node.sumMetadata();
    } else {
        for (node.metadata_entries) |e| {
            if (e > 0 and e - 1 < node.child_ids.len) {
                var child_id = node.child_ids[e - 1];
                var child = Node.linearSearch(nodes, child_id) orelse unreachable;
                value += getNodeValue(nodes, child);
            }
        }
    }

    return value;
}

test "deserialize and get root node value" {
    var allocator = debug.global_allocator;
    var nodes = try deserializeNodes(allocator, test_nums);
    debug.assert(66 == getRootNodeValue(nodes));
}

fn sumAllMetadataEntries(nodes: []Node) u32 {
    var metadata_sum: u32 = 0;
    for (nodes) |n| {
        for (n.metadata_entries) |e| {
            metadata_sum += e;
        }
    }

    return metadata_sum;
}

/// Caller is responsible for freeing returned nodes.
fn deserializeNodes(allocator: *mem.Allocator, nums: []const u32) ![]Node {
    const Task = enum {
        GetHeader,
        Descend,
        Ascend,
        GetMetadata,
    };

    var nodes = std.ArrayList(Node).init(allocator);

    // I need to manage this myself since I've decided not to use recursion
    var node_stack = std.ArrayList(Node).init(allocator);
    defer node_stack.deinit();

    // This is only to get the process started, and should never be included in
    // the returned list of nodes
    var root_node = Node {
        .id = 0,
        .num_children = 1,
        .num_metadata = 0,
        .num_children_found = 0,
        .child_ids = try allocator.alloc(usize, 1),
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
                var num_children = consumeNum(nums, &num_index);
                var num_metadata = consumeNum(nums, &num_index);
                current_node = try Node.init(node_index, num_children, num_metadata, allocator);
                parent_node.child_ids[parent_node.num_children_found] = current_node.id;
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
                    e.* = consumeNum(nums, &num_index);
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

    return nodes.toSlice();
}

test "deserialize and sum metadata" {
    var allocator = debug.global_allocator;
    var nodes = try deserializeNodes(allocator, test_nums);
    debug.assert(138 == sumAllMetadataEntries(nodes));
}

// I was tempted to call this numNum
fn consumeNum(nums: []const u32, index: *usize) u32 {
    var num = nums[index.*];
    index.* += 1;
    return num;
}

const Node = struct {
    id: usize,
    num_children: u32,
    num_metadata: u32,
    num_children_found: u32,
    child_ids: []usize,
    metadata_entries: []u32,

    pub fn init(id: usize, nc: u32, nm: u32, allocator: *mem.Allocator) !Node {
        var ci_buf = try allocator.alloc(usize, nc);
        for (ci_buf) |*ci| {
            ci.* = 0;
        }
        var me_buf = try allocator.alloc(u32, nm);
        for (me_buf) |*e| {
            e.* = 0;
        }
        return Node {
            .id = id,
            .num_children = nc,
            .num_metadata = nm,
            .num_children_found = 0,
            .child_ids = ci_buf,
            .metadata_entries = me_buf,
        };
    }

    pub fn deinit(self: Node, allocator: *mem.Allocator) void {
        allocator.free(self.child_ids);
        allocator.free(self.metadata_entries);
    }

    pub fn print(self: Node) void {
        logDebug("[{}]: ({}/{}, {}) | ", self.id, self.num_children_found, self.num_children, self.num_metadata);
        for (self.metadata_entries) |e| {
            logDebug("{} ", e);
        }
        logDebug("| (");
        for (self.child_ids) |c| {
            logDebug("{} ", c);
        }
        logDebug(")\n");
    }

    pub fn lessThan(l: Node, r: Node) bool {
        return l.id < r.id;
    }

    pub fn linearSearch(nodes: []Node, node_id: usize) ?Node {
        for (nodes) |n, i| {
            if (n.id == node_id) {
                return n;
            }
        }
        return null;
    }

    pub fn sumMetadata(self: Node) u32 {
        var sum: u32 = 0;
        for (self.metadata_entries) |e| {
            sum += e;
        }
        return sum;
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
    var allocator = debug.global_allocator;
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
