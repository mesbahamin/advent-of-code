const std = @import("std");
const debug = std.debug;
const math = std.math;
const mem = std.mem;
const TypeId = @import("builtin").TypeId;

pub fn main() void {
    debug.warn("state {}, rules {}\n", input_initial_state.len, input_rules.len);
    debug.warn("state {}, rules {}\n", test_initial_state.len, test_rules.len);
}

fn Generation(comptime T: type) type {
    return struct {
        const Self = @This();

        gen_num: usize,
        first_plant: isize,
        last_plant: isize,
        pots: []const T,

        fn simNextGeneration(allocator: *std.mem.Allocator, current: Self, rules: u32) Self {
            var next_pots = std.ArrayList(T).init(allocator);
            defer next_pots.deinit();

            comptime const pot_int_highest_bit = @truncate(math.Log2Int(T), @typeInfo(T).Int.bits - 1);
            comptime debug.assert(pot_int_highest_bit == @typeInfo(T).Int.bits - 1);

            var pot_context: u5 = 0;
            var next_pots_pot_int: T = 0;
            var next_pot_bit = pot_int_highest_bit;

            for (current.pots) |pot_int, i| {
                if (i == 0) {
                    // Check the 3 leading pots
                    // 00000
                    //   ^
                    // assign corresponding bit from rules
                    {
                        const new_pot_state = @boolToInt((rules & (u32(1) << pot_context)) != 0);
                        debug.warn("Rule result {b}\n", new_pot_state);
                        next_pots_pot_int |= T(new_pot_state) << next_pot_bit;
                        debug.warn("{x}\n", next_pots_pot_int);
                        if (next_pot_bit == 0) {
                            _ = next_pots.append(next_pots_pot_int);
                            next_pots_pot_int = 0;
                            next_pot_bit = pot_int_highest_bit;
                        }
                    }

                    // 0000X
                    //   ^
                    {
                        var shifted: u5 = 0;
                        var overflowHappened = @shlWithOverflow(u5, pot_context, 1, &shifted);
                        debug.warn("Overflow? {}\n", overflowHappened);

                        pot_context = shifted;
                        debug.warn("Shifted {b}\n", pot_context);

                        const new_bit: u1 = @boolToInt((pot_int & (T(1) << pot_int_highest_bit)) != 0);
                        pot_context |= new_bit;
                        debug.warn("With new bit {b}\n", pot_context);

                        // assign corresponding bit from rules
                        const new_pot_state = @boolToInt((rules & (u32(1) << pot_context)) != 0);
                        debug.warn("Rule result {b}\n", new_pot_state);
                        next_pots_pot_int |= T(new_pot_state) << next_pot_bit;
                        debug.warn("{x}\n", next_pots_pot_int);
                        if (next_pot_bit == 0) {
                            _ = next_pots.append(next_pots_pot_int);
                            next_pots_pot_int = 0;
                            next_pot_bit = pot_int_highest_bit;
                        }
                    }

                    // 000XX
                    //   ^
                    {
                        var shifted: u5 = 0;
                        var overflowHappened = @shlWithOverflow(u5, pot_context, 1, &shifted);
                        debug.warn("Overflow? {}\n", overflowHappened);

                        pot_context = shifted;
                        debug.warn("Shifted {b}\n", pot_context);

                        const new_bit: u1 = @boolToInt((pot_int & (T(1) << pot_int_highest_bit - 1)) != 0);
                        pot_context |= new_bit;
                        debug.warn("With new bit {b}\n", pot_context);

                        // assign corresponding bit from rules
                        const new_pot_state = @boolToInt((rules & (u32(1) << pot_context)) != 0);
                        debug.warn("Rule result {b}\n", new_pot_state);
                        next_pots_pot_int |= T(new_pot_state) << next_pot_bit;
                        debug.warn("{x}\n", next_pots_pot_int);
                    }
                }

                var pot_bit = pot_int_highest_bit - 2;
                while (pot_bit >= 0) : ({ pot_bit -= 1; next_pot_bit -= 1; }) {
                    var shifted: u5 = 0;
                    var overflowHappened = @shlWithOverflow(u5, pot_context, 1, &shifted);
                    debug.warn("Overflow? {}\n", overflowHappened);

                    pot_context = shifted;
                    debug.warn("Shifted {b}\n", pot_context);

                    const new_bit: u1 = @boolToInt((pot_int & (T(1) << pot_bit)) != 0);
                    pot_context |= new_bit;
                    debug.warn("With new bit {b}\n", pot_context);

                    // assign corresponding bit from rules
                    const new_pot_state = @boolToInt((rules & (u32(1) << pot_context)) != 0);
                    debug.warn("Rule result {b}\n", new_pot_state);
                    next_pots_pot_int |= T(new_pot_state) << next_pot_bit;
                    debug.warn("{x}\n", next_pots_pot_int);
                    if (next_pot_bit == 0) {
                        _ = next_pots.append(next_pots_pot_int);
                        next_pots_pot_int = 0;
                        next_pot_bit = pot_int_highest_bit;
                    }

                    if (pot_bit == 0) {
                        break;
                    }
                }
                _ = next_pots.append(next_pots_pot_int);
            }

            // TODO: check the 3 following pots!!

            const result = Self {
                .gen_num = current.gen_num + 1,
                .first_plant = current.first_plant,
                .last_plant = current.last_plant,
                .pots = next_pots.toSlice(),
            };
            return result;
        }
    };
}

test "sim next gen" {
    const TestPotInt = u128;
    const TestGeneration = Generation(TestPotInt);
    var allocator = debug.global_allocator;

    const rules = rulesToInt(u32, test_rules);

    var g = TestGeneration {
        .gen_num = 0,
        .first_plant = 0,
        .last_plant = 24,
        .pots = potsToIntArray(TestPotInt, test_initial_state),
    };

    var expected_first_plant: isize = undefined;
    var expected_last_plant: isize = undefined;
    var expected_pots: []const TestPotInt = potsToIntArray(TestPotInt, ".........................");

    while (g.gen_num <= 20) {
        debug.warn("{}\n", g.gen_num);
        // TODO: replace this with an array of expected `Generation`s
        switch (g.gen_num) {
            0 => {
                expected_first_plant = 0;
                expected_last_plant = 24;
                expected_pots = potsToIntArray(TestPotInt, "#..#.#..##......###...###");
            },
            1 => {
                expected_first_plant = 0;
                expected_last_plant = 24;
                // TODO: Why is the assertion on this passing!?
                expected_pots = potsToIntArray(TestPotInt, "#...#....#.....#..#..#..#");
            },
            2 => {
                expected_first_plant = 0;
                expected_last_plant = 25;
                expected_pots = potsToIntArray(TestPotInt, "##..##...##....#..#..#..##");
            },
            3 => {
                expected_first_plant = -1;
                expected_last_plant = 25;
                expected_pots = potsToIntArray(TestPotInt, "#.#...#..#.#....#..#..#...#");
            },
            4 => {
                expected_first_plant = 0;
                expected_last_plant = 26;
                expected_pots = potsToIntArray(TestPotInt, "#.#..#...#.#...#..#..##..##");
            },
            5 => {
                expected_first_plant = 1;
                expected_last_plant = 26;
                expected_pots = potsToIntArray(TestPotInt, "#...##...#.#..#..#...#...#");
            },
            6 => {
                expected_first_plant = 1;
                expected_last_plant = 27;
                expected_pots = potsToIntArray(TestPotInt, "##.#.#....#...#..##..##..##");
            },
            7 => {
                expected_first_plant = 0;
                expected_last_plant = 27;
                expected_pots = potsToIntArray(TestPotInt, "#..###.#...##..#...#...#...#");
            },
            8 => {
                expected_first_plant = 0;
                expected_last_plant = 28;
                expected_pots = potsToIntArray(TestPotInt, "#....##.#.#.#..##..##..##..##");
            },
            9 => {
                expected_first_plant = 0;
                expected_last_plant = 28;
                expected_pots = potsToIntArray(TestPotInt, "##..#..#####....#...#...#...#");
            },
            10 => {
                expected_first_plant = -1;
                expected_last_plant = 29;
                expected_pots = potsToIntArray(TestPotInt, "#.#..#...#.##....##..##..##..##");
            },
            11 => {
                expected_first_plant = 0;
                expected_last_plant = 29;
                expected_pots = potsToIntArray(TestPotInt, "#...##...#.#...#.#...#...#...#");
            },
            12 => {
                expected_first_plant = 0;
                expected_last_plant = 30;
                expected_pots = potsToIntArray(TestPotInt, "##.#.#....#.#...#.#..##..##..##");
            },
            13 => {
                expected_first_plant = -1;
                expected_last_plant = 30;
                expected_pots = potsToIntArray(TestPotInt, "#..###.#....#.#...#....#...#...#");
            },
            14 => {
                expected_first_plant = -1;
                expected_last_plant = 31;
                expected_pots = potsToIntArray(TestPotInt, "#....##.#....#.#..##...##..##..##");
            },
            15 => {
                expected_first_plant = -1;
                expected_last_plant = 31;
                expected_pots = potsToIntArray(TestPotInt, "##..#..#.#....#....#..#.#...#...#");
            },
            16 => {
                expected_first_plant = -2;
                expected_last_plant = 32;
                expected_pots = potsToIntArray(TestPotInt, "#.#..#...#.#...##...#...#.#..##..##");
            },
            17 => {
                expected_first_plant = -1;
                expected_last_plant = 32;
                expected_pots = potsToIntArray(TestPotInt, "#...##...#.#.#.#...##...#....#...#");
            },
            18 => {
                expected_first_plant = -1;
                expected_last_plant = 33;
                expected_pots = potsToIntArray(TestPotInt, "##.#.#....#####.#.#.#...##...##..##");
            },
            19 => {
                expected_first_plant = -2;
                expected_last_plant = 33;
                expected_pots = potsToIntArray(TestPotInt, "#..###.#..#.#.#######.#.#.#..#.#...#");
            },
            20 => {
                expected_first_plant = -2;
                expected_last_plant = 34;
                expected_pots = potsToIntArray(TestPotInt, "#....##....#####...#######....#.#..##");
            },
            else => unreachable,
        }
        debug.warn("{} == {}\n", expected_pots[0], g.pots[0]);
        debug.assert(expected_first_plant == g.first_plant);
        debug.assert(expected_last_plant == g.last_plant);
        debug.assert(g.pots.len == 1);
        debug.assert(expected_pots.len == 1);
        //debug.assert(mem.eql(TestPotInt, expected_pots, g.pots));
        debug.assert(expected_pots[0] == g.pots[0]);
        g = TestGeneration.simNextGeneration(allocator, g, rules);
    }
}

fn rulesToInt(comptime T: type, rules: []const []const u8) T {
    comptime {
        debug.assert(@typeId(T) == TypeId.Int);
        debug.assert(!@typeInfo(T).Int.is_signed);
    }
    debug.assert(rules.len <= @typeInfo(T).Int.bits);
    var num: T = 0;

    for (rules) |r| {
        var it = mem.split(r, " =>");
        const pattern = potsToInt(u8, it.next().?);
        const result = it.next().?;
        debug.assert(it.next() == null);

        const bit_value = switch (result[0]) {
            '.' => T(0),
            '#' => T(1),
            else => unreachable,
        };

        comptime const ShiftInt = math.Log2Int(T);
        num |= bit_value << @intCast(ShiftInt, pattern);
    }
    return num;
}

test "rules to int" {
    debug.assert(rulesToInt(u32, test_rules) == 0x7CA09D18);
}

fn potsToIntArray(comptime T: type, comptime pots: []const u8) []const T {
    comptime {
        debug.assert(!@typeInfo(T).Int.is_signed);
    }
    comptime const int_bits = @typeInfo(T).Int.bits;

    // round up to account for remainder pots
    comptime const result_array_len: usize = (pots.len + int_bits - 1) / int_bits;

    var result = []T{0} ** result_array_len;

    for (result) |*elem, i| {
        const pot_slice_index = i * int_bits;

        var pot_slice: []const u8 = undefined;

        if (i == result.len - 1) {
            // we need right-padding
            var padded_pots = "." ** int_bits;
            for (pots[pot_slice_index..]) |p, p_i| {
                padded_pots[p_i] = p;
            }
            pot_slice = padded_pots;
        } else {
            const next_slice_index = pot_slice_index + int_bits;
            pot_slice = pots[pot_slice_index..next_slice_index];
        }

        elem.* = potsToInt(T, pot_slice);
    }

    return result;
}

test "pots to int array" {
    {
        const potArray = potsToIntArray(u8, test_initial_state);
        debug.assert(potArray.len == 4);
        debug.assert(potArray[0] == 0x94);  // #..#.#..
        debug.assert(potArray[1] == 0xC0);  //         ##......
        debug.assert(potArray[2] == 0xE3);  //                 ###...##
        debug.assert(potArray[3] == 0x80);  //                         #.......
    }

    {
        const potArray = potsToIntArray(u32, test_initial_state);
        debug.assert(potArray.len == 1);
        debug.assert(potArray[0] == 0x94C0E380);
    }
}

fn potsToInt(comptime T: type, pots: []const u8) T {
    comptime {
        debug.assert(@typeId(T) == TypeId.Int);
        debug.assert(!@typeInfo(T).Int.is_signed);
    }
    comptime const int_bits = @typeInfo(T).Int.bits;
    debug.assert(pots.len <= int_bits);

    var num: T = 0;
    var i: u8 = 0;

    for (pots) |p| {
        if (p == '#') {
            comptime const ShiftInt = math.Log2Int(T);
            num |= T(1) << @intCast(ShiftInt, pots.len - 1 - i);
        }
        i += 1;
    }
    return num;
}

test "pots to int" {
    debug.assert(potsToInt(u8, ".....") == 0);
    debug.assert(potsToInt(u8, "....#") == 1);
    debug.assert(potsToInt(u8, "...##") == 3);
    debug.assert(potsToInt(u8, "..###") == 7);
    debug.assert(potsToInt(u8, ".####") == 15);
    debug.assert(potsToInt(u8, "#####") == 31);
    debug.assert(potsToInt(u8, "####.") == 30);
    debug.assert(potsToInt(u8, "###..") == 28);
    debug.assert(potsToInt(u8, "##...") == 24);
    debug.assert(potsToInt(u8, "#....") == 16);
    debug.assert(potsToInt(u8, "#") == 1);
    debug.assert(potsToInt(u5, "#####") == 31);
    debug.assert(potsToInt(u128, ".#.#.") == 10);
    debug.assert(potsToInt(u128, "#.#.#") == 21);
    debug.assert(potsToInt(u32, test_initial_state) == 0x12981C7);
    debug.assert(potsToInt(u128, input_initial_state) == 0xC9A1A56AFCD5E918842DC9C44);
}

const test_initial_state = "#..#.#..##......###...###";

const test_rules = []const []const u8 {
    "...## => #",
    "..#.. => #",
    ".#... => #",
    ".#.#. => #",
    ".#.## => #",
    ".##.. => #",
    ".#### => #",
    "#.#.# => #",
    "#.### => #",
    "##.#. => #",
    "##.## => #",
    "###.. => #",
    "###.# => #",
    "####. => #",
};

const input_initial_state = "##..#..##.#....##.#..#.#.##.#.#.######..##.#.#.####.#..#...##...#....#....#.##.###..#..###...#...#..";

// Hey, look at that:
//     - there are exactly 32 rules
//     - the patterns, if interpreted as bits, correspond to u8 0 through 31
//     - the results, by themselves, could fit in a single u32
// That's... interesting...
const input_rules = []const []const u8 {
    "#..#. => .",
    ".#..# => #",
    "..#.# => .",
    "..... => .",
    ".#... => #",
    "#..## => #",
    "..##. => #",
    "#.##. => #",
    "#.#.# => .",
    "###.# => #",
    ".#### => .",
    "..### => .",
    ".###. => .",
    "#.#.. => #",
    "###.. => .",
    "##.#. => .",
    "##..# => .",
    "##.## => .",
    "#.### => .",
    "...## => #",
    "##... => #",
    "####. => .",
    ".#.## => .",
    "#...# => #",
    ".#.#. => #",
    "....# => .",
    ".##.. => .",
    "...#. => .",
    "..#.. => .",
    "#.... => .",
    ".##.# => #",
    "##### => #",
};
