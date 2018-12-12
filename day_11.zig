const std = @import("std");
const debug = std.debug;
const mem = std.mem;

const grid_serial_number: u32 = 5791;
const grid_side_len = 300;

pub fn main() void {
    const result = regionOfHighestTotalPower(grid_serial_number);
    debug.warn("11-1: {}\n", result);

    // Horrible brute-force algorithm. Uncomment at your own risk.
    //debug.warn("11-2: ");
    //regionOfHighestTotalPowerUltimateSupremeExtremeBruteForceImSoTiredExtravaganza(grid_serial_number);
}

fn regionOfHighestTotalPowerUltimateSupremeExtremeBruteForceImSoTiredExtravaganza(gsn: u32) void {
    var grid = []i32{0} ** (grid_side_len * grid_side_len);

    for (grid) |*cell, i| {
        var coord = point_from_index(i, grid_side_len);

        // grid is 1 based, though array is 0 based
        coord.x += 1;
        coord.y += 1;

        cell.* = getFuelCellPower(coord.x, coord.y, gsn);
    }

    var highest_highest_power: i32 = 0;
    var highest_highest_power_region = V2.init(1, 1);
    var highest_square_side_len: u32 = 1;

    var square_side_len: u32 = 1;
    while (square_side_len <= 300) : (square_side_len += 1) {
        debug.warn("{}\n", square_side_len);
        var highest_power: i32 = 0;
        var highest_power_region = V2.init(1, 1);

        for (grid) |cell, i| {
            const array_coord = point_from_index(i, grid_side_len);
            const cell_coord = V2.init(array_coord.x + 1, array_coord.y + 1);

            const search_threshold = grid_side_len - square_side_len;
            if (cell_coord.x >= search_threshold or cell_coord.y >= search_threshold) {
                continue;
            }

            var sum: i32 = 0;
            var square_x: u32 = 0;
            while (square_x < square_side_len) : (square_x += 1) {
                var square_y: u32 = 0;
                while (square_y < square_side_len) : (square_y += 1) {
                    sum += grid[index_from_point(array_coord.x + square_x, array_coord.y + square_y, grid_side_len)];
                }
            }

            if (sum > highest_power) {
                highest_power = sum;
                highest_power_region = cell_coord;
            }
        }

        if (highest_power > highest_highest_power) {
            highest_highest_power = highest_power;
            highest_highest_power_region = highest_power_region;
            highest_square_side_len = square_side_len;
        }
    }

    debug.warn("{},{}\n", highest_highest_power_region, highest_square_side_len);
}

fn regionOfHighestTotalPower(gsn: u32) V2{
    var grid = []i32{0} ** (grid_side_len * grid_side_len);

    for (grid) |*cell, i| {
        var coord = point_from_index(i, grid_side_len);

        // grid is 1 based, though array is 0 based
        coord.x += 1;
        coord.y += 1;

        cell.* = getFuelCellPower(coord.x, coord.y, gsn);
    }

    var square_side_len: u32 = 3;
    var highest_power: i32 = 0;
    var highest_power_region = V2.init(1, 1);

    for (grid) |cell, i| {
        const array_coord = point_from_index(i, grid_side_len);
        const cell_coord = V2.init(array_coord.x + 1, array_coord.y + 1);

        const search_threshold = grid_side_len - square_side_len;
        if (cell_coord.x >= search_threshold or cell_coord.y >= search_threshold) {
            continue;
        }

        var sum: i32 = 0;
        var square_x: u32 = 0;
        while (square_x < square_side_len) : (square_x += 1) {
            var square_y: u32 = 0;
            while (square_y < square_side_len) : (square_y += 1) {
                sum += grid[index_from_point(array_coord.x + square_x, array_coord.y + square_y, grid_side_len)];
            }
        }

        if (sum > highest_power) {
            highest_power = sum;
            highest_power_region = cell_coord;
        }
    }
    return highest_power_region;
}

test "region of highest total power" {
    debug.assert(V2.eq(V2.init(33, 45), regionOfHighestTotalPower(18)));
    debug.assert(V2.eq(V2.init(21, 61), regionOfHighestTotalPower(42)));
}

fn getFuelCellPower(cell_x: u32, cell_y: u32, gsn: u32) i32 {
    const rack_id = cell_x + 10;
    var power_level: i32 = @intCast(i32, rack_id * cell_y);
    power_level += @intCast(i32, gsn);
    power_level *= @intCast(i32, rack_id);
    power_level = hundredsDigit(power_level);
    power_level -= 5;
    return power_level;
}

test "get fuel cell power" {
    debug.assert(4 == getFuelCellPower(3, 5, 8));
    debug.assert(-5 == getFuelCellPower(122, 79, 57));
    debug.assert(0 == getFuelCellPower(217, 196, 39));
    debug.assert(4 == getFuelCellPower(101, 153, 71));
}

inline fn hundredsDigit(n: i32) i32 {
    return @mod(@divTrunc(n, 100), 10);
}

test "hundreds digit" {
    debug.assert(0 == hundredsDigit(0));
    debug.assert(0 == hundredsDigit(10));
    debug.assert(1 == hundredsDigit(100));
    debug.assert(0 == hundredsDigit(1000));
    debug.assert(3 == hundredsDigit(12345));
}

fn point_from_index(i: usize, stride: usize) V2 {
    var x: u32 = @intCast(u32, i % stride);
    var y: u32 = @intCast(u32, @divTrunc(i, stride));
    return V2.init(x, y);
}

test "point from index" {
    debug.assert(V2.eq(V2.init(0, 0), point_from_index(0, 5)));
    debug.assert(V2.eq(V2.init(1, 1), point_from_index(6, 5)));
    debug.assert(V2.eq(V2.init(2, 1), point_from_index(7, 5)));
    debug.assert(V2.eq(V2.init(4, 2), point_from_index(14, 5)));
}

inline fn index_from_point(x: u32, y: u32, stride: usize) usize {
    return y * stride + x;
}

test "index from point" {
    debug.assert(0 == index_from_point(0, 0, 5));
    debug.assert(6 == index_from_point(1, 1, 5));
    debug.assert(7 == index_from_point(2, 1, 5));
    debug.assert(14 == index_from_point(4, 2, 5));
}

const V2 = struct {
    x: u32,
    y: u32,

    pub fn init(x: u32, y: u32) V2 {
        return V2 {
            .x = x,
            .y = y,
        };
    }

    pub fn eq(vec1: V2, vec2: V2) bool {
        return vec1.x == vec2.x and vec1.y == vec2.y;
    }
};
