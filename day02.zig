const std = @import("std");
const dbg = std.debug;
const mem = std.mem;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.direct_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var program: [input.len]u32 = undefined;
    mem.copy(u32, program[0..input.len], input[0..input.len]);

    program[1] = 12;
    program[2] = 2;
    var final_state = try run_intcode_program(allocator, program);

    dbg.warn("02-1: {}\n", final_state[0]);
}

const OpCode = enum(u32) {
    Add = 1,
    Mult = 2,
    Term = 99,
};

fn run_intcode_program(allocator: *mem.Allocator, program: []const u32) ![]const u32 {
    const num_codes = program.len;
    var p = try allocator.alloc(u32, num_codes);
    mem.copy(u32, p[0..num_codes], program[0..num_codes]);
    var opcode = OpCode.Add;
    var instruction_pointer: usize = 0;
    while (true) : (instruction_pointer += 4) {
        dbg.assert(instruction_pointer < num_codes);
        opcode = @intToEnum(OpCode, p[instruction_pointer]);
        switch (opcode) {
            .Add => {
                var a = p[instruction_pointer + 1];
                var b = p[instruction_pointer + 2];
                var dest = p[instruction_pointer + 3];
                p[dest] = p[a] + p[b];
            },
            .Mult => {
                var a = p[instruction_pointer + 1];
                var b = p[instruction_pointer + 2];
                var dest = p[instruction_pointer + 3];
                p[dest] = p[a] * p[b];
            },
            .Term => {
                break;
            },
        }
    }
    return p;
}

test "run intcode program" {
    var a = dbg.global_allocator;
    dbg.assert(mem.eql(u32, try run_intcode_program(a, [_]u32{ 1, 0, 0, 0, 99 }), [_]u32{ 2, 0, 0, 0, 99 }));
    dbg.assert(mem.eql(u32, try run_intcode_program(a, [_]u32{ 2, 3, 0, 3, 99 }), [_]u32{ 2, 3, 0, 6, 99 }));
    dbg.assert(mem.eql(u32, try run_intcode_program(a, [_]u32{ 2, 4, 4, 5, 99, 0 }), [_]u32{ 2, 4, 4, 5, 99, 9801 }));
    dbg.assert(mem.eql(u32, try run_intcode_program(a, [_]u32{ 1, 1, 1, 4, 99, 5, 6, 0, 99 }), [_]u32{ 30, 1, 1, 4, 2, 5, 6, 0, 99 }));
}

const input = [_]u32{
    1,  0,   0,   3,
    1,  1,   2,   3,
    1,  3,   4,   3,
    1,  5,   0,   3,
    2,  9,   1,   19,
    1,  19,  5,   23,
    1,  23,  5,   27,
    2,  27,  10,  31,
    1,  31,  9,   35,
    1,  35,  5,   39,
    1,  6,   39,  43,
    2,  9,   43,  47,
    1,  5,   47,  51,
    2,  6,   51,  55,
    1,  5,   55,  59,
    2,  10,  59,  63,
    1,  63,  6,   67,
    2,  67,  6,   71,
    2,  10,  71,  75,
    1,  6,   75,  79,
    2,  79,  9,   83,
    1,  83,  5,   87,
    1,  87,  9,   91,
    1,  91,  9,   95,
    1,  10,  95,  99,
    1,  99,  13,  103,
    2,  6,   103, 107,
    1,  107, 5,   111,
    1,  6,   111, 115,
    1,  9,   115, 119,
    1,  119, 9,   123,
    2,  123, 10,  127,
    1,  6,   127, 131,
    2,  131, 13,  135,
    1,  13,  135, 139,
    1,  9,   139, 143,
    1,  9,   143, 147,
    1,  147, 13,  151,
    1,  151, 9,   155,
    1,  155, 13,  159,
    1,  6,   159, 163,
    1,  13,  163, 167,
    1,  2,   167, 171,
    1,  171, 13,  0,
    99, 2,   0,   14,
    0,
};
