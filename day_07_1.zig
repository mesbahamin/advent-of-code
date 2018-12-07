const std = @import("std");
const debug = std.debug;
const mem = std.mem;

pub fn main() !void {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    const result = try step_order(allocator, dependency_hierarchy);
    defer allocator.free(result);
    debug.warn("07-1: {}\n", result);
}

fn step_order(allocator: *mem.Allocator, rules: []const Rule) ![]const u8 {
    const step_range = set_of_all_steps(rules);
    const largest_letter = step_range[step_range.len - 1];

    var steps = try allocator.alloc(u8, step_range.len);
    for (steps) |*s, i| {
        s.* = next_step(steps[0..i], step_range, rules);
    }

    return steps;
}

test "step order" {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    debug.assert(mem.eql(u8, "CABDFE", try step_order(allocator, test_hierarchy)));
}

fn next_step(done_steps: []u8, step_range: []const u8, rules: []const Rule) u8 {
    if (done_steps.len == step_range.len - 1) {
        // We've reached the end. There's only one undone step.
        for (step_range) |s| {
            var step_is_done = false;
            for (done_steps) |done| {
                if (done == s) {
                    step_is_done = true;
                }
            }
            if (!step_is_done) {
                return s;
            }
        }
    }

    debug.assert(rules.len < 1000);
    var relevant_rules_array = []bool{true} ** 1000;
    var relevant_rules = relevant_rules_array[0..rules.len];

    // cull irrelevant rules
    for (done_steps) |s| {
        for (rules) |r, i| {
            if (r.p == s) {
                relevant_rules[i] = false;
            }
        }
    }

    // Make sure we didn't cull rules inconsistently
    for (done_steps) |s| {
        for (rules) |r, i| {
            if (relevant_rules[i]) {
                debug.assert(r.p != s);
                debug.assert(r.c != s);
            }
        }
    }

    {
        // the next step is the first one alphabetically that:
        //    - exists in the rules as a parent
        //    - does not exist in the rules as a child
        var step: u8 = step_range[0];
        while (step <= step_range[step_range.len - 1]) : (step += 1) {
            var step_exists_as_parent: bool = false;
            var step_exists_as_child: bool = false;
            for (rules) |r, i| {
                if (relevant_rules[i]) {
                    if (step == r.p) {
                        step_exists_as_parent = true;
                    } else if (step == r.c) {
                        step_exists_as_child = true;
                    }
                }
            }
            if (step_exists_as_parent and !step_exists_as_child) {
                return step;
            }
        }
    }
    unreachable;
}

fn set_of_all_steps(rules: []const Rule) []const u8 {
    // This assumes no letters in the alphabetical range are skipped
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var largest_letter: u8 = 'A';
    for (rules) |r| {
        if (r.p > largest_letter) {
            largest_letter = r.p;
        }
        if (r.c > largest_letter) {
            largest_letter = r.c;
        }
    }
    var num_letters = largest_letter - 'A' + 1;
    var step_range = letters[0..num_letters];
    debug.assert(step_range.len <= 26);
    return step_range;
}

const Rule = struct {
    p: u8,
    c: u8,
};

inline fn rule(parent: u8, child: u8) Rule {
    return Rule {
        .p = parent,
        .c = child,
    };
}

const test_hierarchy = []const Rule {
    rule('C', 'A'),
    rule('C', 'F'),
    rule('A', 'B'),
    rule('A', 'D'),
    rule('B', 'E'),
    rule('D', 'E'),
    rule('F', 'E'),
};

const dependency_hierarchy = []const Rule {
    rule('X', 'C'),
    rule('C', 'G'),
    rule('F', 'G'),
    rule('U', 'Y'),
    rule('O', 'S'),
    rule('D', 'N'),
    rule('M', 'H'),
    rule('J', 'Q'),
    rule('G', 'R'),
    rule('I', 'N'),
    rule('R', 'K'),
    rule('A', 'Z'),
    rule('Y', 'L'),
    rule('H', 'P'),
    rule('K', 'S'),
    rule('Z', 'P'),
    rule('T', 'S'),
    rule('N', 'P'),
    rule('E', 'S'),
    rule('S', 'W'),
    rule('W', 'V'),
    rule('L', 'V'),
    rule('P', 'B'),
    rule('Q', 'V'),
    rule('B', 'V'),
    rule('P', 'Q'),
    rule('S', 'V'),
    rule('C', 'Q'),
    rule('I', 'H'),
    rule('A', 'E'),
    rule('H', 'Q'),
    rule('G', 'V'),
    rule('N', 'L'),
    rule('R', 'Q'),
    rule('W', 'L'),
    rule('X', 'L'),
    rule('X', 'J'),
    rule('W', 'P'),
    rule('U', 'B'),
    rule('P', 'V'),
    rule('O', 'P'),
    rule('W', 'Q'),
    rule('S', 'Q'),
    rule('U', 'Z'),
    rule('Z', 'T'),
    rule('M', 'T'),
    rule('A', 'P'),
    rule('Z', 'B'),
    rule('N', 'S'),
    rule('H', 'N'),
    rule('J', 'E'),
    rule('M', 'J'),
    rule('R', 'A'),
    rule('A', 'Y'),
    rule('F', 'V'),
    rule('L', 'P'),
    rule('K', 'L'),
    rule('F', 'P'),
    rule('G', 'L'),
    rule('I', 'Q'),
    rule('C', 'L'),
    rule('I', 'Y'),
    rule('G', 'B'),
    rule('H', 'L'),
    rule('X', 'U'),
    rule('I', 'K'),
    rule('R', 'N'),
    rule('I', 'L'),
    rule('M', 'I'),
    rule('K', 'V'),
    rule('G', 'E'),
    rule('F', 'B'),
    rule('O', 'Y'),
    rule('Y', 'Q'),
    rule('F', 'K'),
    rule('N', 'W'),
    rule('O', 'R'),
    rule('N', 'E'),
    rule('M', 'V'),
    rule('H', 'T'),
    rule('Y', 'T'),
    rule('F', 'J'),
    rule('F', 'O'),
    rule('W', 'B'),
    rule('T', 'E'),
    rule('T', 'P'),
    rule('F', 'M'),
    rule('U', 'I'),
    rule('H', 'S'),
    rule('S', 'P'),
    rule('T', 'W'),
    rule('A', 'N'),
    rule('O', 'N'),
    rule('L', 'B'),
    rule('U', 'K'),
    rule('Z', 'W'),
    rule('X', 'D'),
    rule('Z', 'L'),
    rule('I', 'T'),
    rule('O', 'W'),
    rule('I', 'B'),
};
