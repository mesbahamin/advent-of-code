const std = @import("std");
const debug = std.debug;
const heap = std.heap;
const LinkedList = std.LinkedList;
const mem = std.mem;

const Node = LinkedList(u32).Node;
const debug_logging: bool = false;

pub fn main() void {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    debug.warn("09-1: {}\n", computeHighScore(allocator, 465, 71498));
    debug.warn("09-2: {}\n", computeHighScore(allocator, 465, 71498 * 100));
}

fn printTurn(player_turn: ?u32, circle: LinkedList(u32), current_num: u32) void {
    if (player_turn) |t| {
        logDebug("[{}] ", t);
    } else {
        logDebug("[-] ");
    }

    var it = circle.first;
    var i: usize = 0;
    while (it) |node| : ({ it = node.next; i += 1; }) {
        if (i >= circle.len) {
            break;
        }
        if (node.data == current_num) {
            logDebug("({}) ", node.data);
        } else {
            logDebug("{} ", node.data);
        }
    }

    logDebug("\n");
}

fn computeHighScore(allocator: *mem.Allocator, num_players: u32, num_marbles: u32) !u32 {
    var scores = try allocator.alloc(u32, num_players);
    defer allocator.free(scores);
    for (scores) |*s| {
        s.* = 0;
    }

    const buf = try allocator.alloc(u8, num_marbles * @sizeOf(Node));
    defer allocator.free(buf);

    // TODO: Why does this explode my memory usage!?
    //const node_allocator = allocator;

    const node_allocator = &heap.FixedBufferAllocator.init(buf[0..]).allocator;

    var circle = LinkedList(u32).init();

    var initial_marble = try circle.createNode(0, node_allocator);
    defer circle.destroyNode(initial_marble, node_allocator);

    circle.first = initial_marble;
    circle.last = circle.first;
    circle.first.?.next = circle.first;
    circle.first.?.prev = circle.first;
    circle.len = 1;

    var current: *Node = circle.first orelse unreachable;
    var last_played: u32 = 0;
    var turn: u32 = 1;

    while (last_played < num_marbles) : (last_played += 1) {
        var to_be_played = last_played + 1;

        if (to_be_played % 23 == 0) {
            var to_remove = current.prev.?.prev.?.prev.?.prev.?.prev.?.prev.?.prev orelse unreachable;
            defer circle.destroyNode(to_remove, node_allocator);

            var to_make_current = to_remove.next orelse unreachable;
            circle.remove(to_remove);
            current = to_make_current;

            scores[turn] += (to_be_played + to_remove.data);
        } else {
            var new_marble = try circle.createNode(to_be_played, node_allocator);
            var two_clockwise_from_current = current.next.?.next orelse unreachable;
            circle.insertBefore(two_clockwise_from_current, new_marble);
            current = new_marble;
        }
        turn += 1;
        turn %= num_players;
    }

    var high_score: u32 = 0;
    for (scores) |s| {
        if (s > high_score) {
            high_score = s;
        }
    }
    logDebug("High Score: {}\n", high_score);
    return high_score;
}

test "compute high score" {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    debug.warn("\n");
    debug.assert(32 == try computeHighScore(allocator, 9, 25));
    debug.assert(8317 == try computeHighScore(allocator, 10, 1618));
    debug.assert(146373 ==  try computeHighScore(allocator, 13, 7999));
    debug.assert(2764 == try computeHighScore(allocator, 17, 1104));
    debug.assert(54718 == try computeHighScore(allocator, 21, 6111));
    debug.assert(37305 == try computeHighScore(allocator, 30, 5807));
}

fn logDebug(comptime format_str: []const u8, args: ...) void {
    if (debug_logging) {
        debug.warn(format_str, args);
    }
}
