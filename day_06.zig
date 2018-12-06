const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;
const mem = std.mem;
const math = std.math;

pub fn main() !void {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    var result1 = try biggest_finite_area(allocator, coordinates);
    debug.warn("06-1: {}\n", result1);
    var result2 = try safe_area(coordinates, 10000);
    debug.warn("06-2: {}\n", result2);
}

fn safe_area(coords: []const V2, distance_threshold: usize) !u32 {
    var max = point(0, 0);
    for (coords) |c| {
        //V2.print(c);
        if (c.x > max.x) {
            max.x = c.x;
        }
        if (c.y > max.y) {
            max.y = c.y;
        }
    }

    const field_stride = max.x + 1;
    const field_size: usize = field_stride * (max.y + 1);

    var area: u32 = 0;
    var cell_i: usize = 0;
    while (cell_i < field_size) : (cell_i += 1) {
        var distance_sum: usize = 0;
        for (coords) |coord, coord_i| {
            var dist = try manhattan_distance(point_from_index(cell_i, field_stride), coord);
            distance_sum += dist;
            if (distance_sum >= distance_threshold) {
                break;
            }
        }
        if (distance_sum < distance_threshold) {
            area += 1;
        }
    }

    return area;
}

test "safe area" {
    const test_threshold: usize = 32;
    const test_coords = []const V2 {
        point(1, 1),
        point(1, 6),
        point(8, 3),
        point(3, 4),
        point(5, 5),
        point(8, 9),
    };

    debug.assert(16 == try safe_area(test_coords, test_threshold));
}

fn biggest_finite_area(allocator: *mem.Allocator, coords: []const V2) !u32 {
    var max = point(0, 0);
    for (coords) |c| {
        //V2.print(c);
        if (c.x > max.x) {
            max.x = c.x;
        }
        if (c.y > max.y) {
            max.y = c.y;
        }
    }

    var field_stride = max.x + 1;
    var field = try allocator.alloc(isize, field_stride * (max.y + 1));
    defer allocator.free(field);

    for (field) |*cell, cell_i| {
        cell.* = -1;
        var closest_distance = field.len * 1000;

        for (coords) |coord, coord_i| {
            var dist = try manhattan_distance(point_from_index(cell_i, field_stride), coord);
            if (dist < closest_distance) {
                closest_distance = dist;
                cell.* = @intCast(isize, coord_i);
            } else if (dist == closest_distance) {
                // when a cell of the field contains -1, this represents a tie
                cell.* = -1;
            }
        }
    }

    var coord_counts = try allocator.alloc(isize, coords.len);
    defer allocator.free(coord_counts);
    for (coord_counts) |*count| {
        count.* = 0;
    }

    for (field) |cell, cell_i| {
        if (cell < 0) {
            continue;
        }

        var current_cell = point_from_index(cell_i, field_stride);

        if (current_cell.x == 0
            or current_cell.y == 0
            or current_cell.x >= max.x
            or current_cell.y >= max.y) {
            // when a coord_count contains -1, this means that the area of that
            // coord is infinite
            coord_counts[@intCast(usize, cell)] = -1;
        } else {
            if (coord_counts[@intCast(usize, cell)] != -1) {
                coord_counts[@intCast(usize, cell)] += 1;
            }
        }
    }

    var max_area: isize = 0;
    var max_coord: usize = 0;
    for (coord_counts) |count, coord_i| {
        //debug.warn("[{}]: {}\n", coord_i, count);
        if (count > max_area) {
            max_area = count;
            max_coord = coord_i;
        }
    }
    debug.assert(max_area >= 0);

    return @intCast(u32, max_area);
}

test "biggest finite area" {
    const test_coords = []const V2 {
        point(1, 1),
        point(1, 6),
        point(8, 3),
        point(3, 4),
        point(5, 5),
        point(8, 9),
    };

    var allocator = &std.heap.DirectAllocator.init().allocator;
    debug.assert(17 == try biggest_finite_area(allocator, test_coords));
}

fn point_from_index(i: usize, stride: usize) V2 {
    var x: u32 = @intCast(u32, i % stride);
    var y: u32 = @intCast(u32, @divTrunc(i, stride));
    return V2 {
        .x = x,
        .y = y
    };
}

// 0  1  2  3  4
// 5  6  7  8  9
// 10 11 12 13 14
test "point from index" {
    debug.assert(0 == point_from_index(0, 5).x);
    debug.assert(0 == point_from_index(0, 5).y);

    debug.assert(1 == point_from_index(6, 5).x);
    debug.assert(1 == point_from_index(6, 5).y);

    debug.assert(2 == point_from_index(7, 5).x);
    debug.assert(1 == point_from_index(7, 5).y);

    debug.assert(4 == point_from_index(14, 5).x);
    debug.assert(2 == point_from_index(14, 5).y);
}

fn manhattan_distance(p1: V2, p2: V2) !u32 {
    var x_dist = (try math.absInt(@intCast(i32, p1.x) - @intCast(i32, p2.x)));
    var y_dist = (try math.absInt(@intCast(i32, p1.y) - @intCast(i32, p2.y)));
    return @intCast(u32, x_dist + y_dist);
}

test "manhattan" {
    debug.assert(5 == try manhattan_distance(point(1, 1), point(3, 4)));
    debug.assert(5 == try manhattan_distance(point(3, 4), point(1, 1)));
    debug.assert(0 == try manhattan_distance(point(13, 14), point(13, 14)));
}

const V2 = struct {
    x: u32,
    y: u32,

    fn print(self: V2) void {
        debug.warn("({}, {})\n", self.x, self.y);
    }
};

inline fn point(x: u32, y: u32) V2 {
    return V2 {
        .x = x,
        .y = y,
    };
}

const coordinates = comptime block: {
    break :block []V2{
        point(67, 191),
        point(215, 237),
        point(130, 233),
        point(244, 61),
        point(93, 93),
        point(145, 351),
        point(254, 146),
        point(260, 278),
        point(177, 117),
        point(89, 291),
        point(313, 108),
        point(145, 161),
        point(143, 304),
        point(329, 139),
        point(153, 357),
        point(217, 156),
        point(139, 247),
        point(304, 63),
        point(202, 344),
        point(140, 302),
        point(233, 127),
        point(260, 251),
        point(235, 46),
        point(357, 336),
        point(302, 284),
        point(313, 260),
        point(135, 40),
        point(95, 57),
        point(227, 202),
        point(277, 126),
        point(163, 99),
        point(232, 271),
        point(130, 158),
        point(72, 289),
        point(89, 66),
        point(94, 111),
        point(210, 184),
        point(139, 58),
        point(99, 272),
        point(322, 148),
        point(209, 111),
        point(170, 244),
        point(230, 348),
        point(112, 200),
        point(287, 55),
        point(320, 270),
        point(53, 219),
        point(42, 52),
        point(313, 205),
        point(166, 259),
    };
};
