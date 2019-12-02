const std = @import("std");
const debug = std.debug;
const mem = std.mem;

const debug_logging: bool = false;

pub fn main() !void {
    var allocator = &std.heap.DirectAllocator.init().allocator;

    debug.warn("10-1:");
    try printMessage(allocator, input_lights);

    const result2 = try getTimeOfSmallestBoundingArea(allocator, input_lights);
    debug.warn("10-2: {}\n", result2);
}

fn printMessage(allocator: *mem.Allocator, lights: []const Light) !void {
    var message_time = try getTimeOfSmallestBoundingArea(allocator, lights);
    var lights_prime = try getLightsAtTime(allocator, lights, message_time);
    printLights(lights_prime);
}

test "print message" {
    var allocator = debug.global_allocator;
    try printMessage(allocator, test_lights);
}

fn printLights(lights: []const Light) void {
    var bound = getBoundingArea(lights);

    debug.warn("\n");
    var cursor = bound.nw;
    while (cursor.y <= bound.se.y) : (cursor.y += 1) {
        cursor.x = bound.nw.x;
        while (cursor.x <= bound.se.x) : (cursor.x += 1) {
            var light_is_here: bool = false;
            for (lights) |l| {
                if (V2.equal(l.p, cursor)) {
                    light_is_here = true;
                    debug.warn("#");
                    break;
                }
            }
            if (!light_is_here) {
                debug.warn(".");
            }
        }
        debug.warn("\n");
    }
    debug.warn("\n");
}

/// Caller responsible for freeing returned buffer
fn getLightsAtTime(allocator: *mem.Allocator, lights: []const Light, time: u64) ![]Light {
    var lights_prime = try allocator.alloc(Light, lights.len);
    mem.copy(Light, lights_prime, lights);

    for (lights_prime) |*l| {
        l.p = V2.add(l.p, V2.scale(l.v, @intCast(i64, time)));
    }

    return lights_prime;
}

fn getTimeOfSmallestBoundingArea(allocator: *mem.Allocator, lights: []const Light) !u64 {
    var time: u64 = 0;
    var area = getBoundingArea(lights).area();
    var last_area: isize = 0;

    while (true) {
        last_area = area;
        time += 1;

        var lights_prime = try getLightsAtTime(allocator, lights, time);
        defer allocator.free(lights_prime);

        area = getBoundingArea(lights_prime).area();
        if (area > last_area) {
            break;
        }
    }

    return time - 1;
}

test "get time of smallest bounding area" {
    var allocator = debug.global_allocator;
    debug.assert(3 == try getTimeOfSmallestBoundingArea(allocator, test_lights));
}

fn getBoundingArea(lights: []const Light) Rect {
    var min = V2.init(@maxValue(i64), @maxValue(i64));
    var max = V2.init(@minValue(i64), @minValue(i64));

    for (lights) |l| {
        if (l.p.x < min.x) {
            min.x = l.p.x;
        } else if (l.p.x > max.x) {
            max.x = l.p.x;
        }
        if (l.p.y < min.y) {
            min.y = l.p.y;
        } else if (l.p.y > max.y) {
            max.y = l.p.y;
        }
    }

    debug.assert(min.x < max.x);
    debug.assert(min.y < max.y);

    var area = Rect {
        .nw = min,
        .se = max,
    };
    return area;
}

test "get bounding area" {
    debug.assert(352 == getBoundingArea(test_lights).area());
}

const Light = struct {
    p: V2,
    v: V2,
};

const Rect = struct {
    nw: V2,
    se: V2,

    pub fn area(self: Rect) isize {
        var xdim = self.se.x - self.nw.x + 1;
        var ydim = self.se.y - self.nw.y + 1;
        return xdim * ydim;
    }
};

const V2 = struct {
    x: i64,
    y: i64,

    pub fn init(_x: i64, _y: i64) V2 {
        return V2 {
            .x = _x,
            .y = _y,
        };
    }

    pub fn equal(self: V2, other: V2) bool {
        return (self.x == other.x and self.y == other.y);
    }

    pub fn add(vec1: V2, vec2: V2) V2 {
        return V2.init(vec1.x + vec2.x, vec1.y + vec2.y);
    }

    pub fn scale(self: V2, scalar: i64) V2 {
        return V2.init(self.x * scalar, self.y * scalar);
    }

    pub fn print(v: V2) void {
        logDebug("({}, {})\n", v.x, v.y);
    }
};

test "v2 add" {
    debug.assert(V2.equal(V2.init(1, 3), V2.add(V2.init(0, 0), V2.init(1, 3))));
    debug.assert(V2.equal(V2.init(299, 11), V2.add(V2.init(-23, 14), V2.init(322, -3))));
}

test "v2 scale" {
    debug.assert(V2.equal(V2.init(0, 0), V2.init(0, 0).scale(100)));
    debug.assert(V2.equal(V2.init(-2400, 3000), V2.init(-24, 30).scale(100)));
    debug.assert(V2.equal(V2.init(-1, 1), V2.init(1, -1).scale(-1)));
}

fn logDebug(comptime format_str: []const u8, args: ...) void {
    if (debug_logging) {
        debug.warn(format_str, args);
    }
}

inline fn light(px: i64, py: i64, vx: i64, vy: i64) Light {
    return Light {
        .p = V2.init(px, py),
        .v = V2.init(vx, vy),
    };
}

const test_lights = []Light {
    light( 9,  1,  0,  2),
    light( 7,  0, -1,  0),
    light( 3, -2, -1,  1),
    light( 6, 10, -2, -1),
    light( 2, -4,  2,  2),
    light(-6, 10,  2, -2),
    light( 1,  8,  1, -1),
    light( 1,  7,  1,  0),
    light(-3, 11,  1, -2),
    light( 7,  6, -1, -1),
    light(-2,  3,  1,  0),
    light(-4,  3,  2,  0),
    light(10, -3, -1,  1),
    light( 5, 11,  1, -2),
    light( 4,  7,  0, -1),
    light( 8, -2,  0,  1),
    light(15,  0, -2,  0),
    light( 1,  6,  1,  0),
    light( 8,  9,  0, -1),
    light( 3,  3, -1,  1),
    light( 0,  5,  0, -1),
    light(-2,  2,  2,  0),
    light( 5, -2,  1,  2),
    light( 1,  4,  2,  1),
    light(-2,  7,  2, -2),
    light( 3,  6, -1, -1),
    light( 5,  0,  1,  0),
    light(-6,  0,  2,  0),
    light( 5,  9,  1, -2),
    light(14,  7, -2,  0),
    light(-3,  6,  2, -1),
};

const input_lights = []Light {
    light( 31766, -52454, -3,  5),
    light(-52374, -41935,  5,  4),
    light( 31758, -31427, -3,  3),
    light(-41862,  31671,  4, -3),
    light( 10747, -41934, -1,  4),
    light( 21267,  42181, -2, -4),
    light( 52759, -20913, -5,  2),
    light( 31734,  52701, -3, -5),
    light(-41823,  31669,  4, -3),
    light(-52346,  42184,  5, -4),
    light(-20801, -52451,  2,  5),
    light( 31760, -20904, -3,  2),
    light(-31356, -10397,  3,  1),
    light(-41823, -41934,  4,  4),
    light( 10724, -10389, -1,  1),
    light(-31344, -31427,  3,  3),
    light(-41826,  42186,  4, -4),
    light(-52393,  42186,  5, -4),
    light( 42281,  52698, -4, -5),
    light( 10700, -10398, -1,  1),
    light( 21259,  31667, -2, -3),
    light( 21215,  31662, -2, -3),
    light(-10294,  10635,  1, -1),
    light( 31734, -10392, -3,  1),
    light( 52764,  52698, -5, -5),
    light(-52394,  21148,  5, -2),
    light(-20809, -31428,  2,  3),
    light(-52333,  31666,  5, -3),
    light( 31787, -20913, -3,  2),
    light( 52776, -10391, -5,  1),
    light(-52393, -52449,  5,  5),
    light( 31768,  52701, -3, -5),
    light( 31734,  21155, -3, -2),
    light(-41847, -52455,  4,  5),
    light( 21220,  21147, -2, -2),
    light( 42273,  10640, -4, -1),
    light( 10753,  52696, -1, -5),
    light(-10309, -10389,  1,  1),
    light( 42241,  21149, -4, -2),
    light( 52806,  52701, -5, -5),
    light(-20801,  31670,  2, -3),
    light( 10720,  21152, -1, -2),
    light( 31737,  42181, -3, -4),
    light(-31332, -20913,  3,  2),
    light(-10321,  52695,  1, -5),
    light(-10294,  31664,  1, -3),
    light(-10331, -41943,  1,  4),
    light( 52788, -10397, -5,  1),
    light( 52766, -31428, -5,  3),
    light(-31332, -52458,  3,  5),
    light(-31356, -20909,  3,  2),
    light(-10329, -52453,  1,  5),
    light(-31346, -31419,  3,  3),
    light( 31787,  10638, -3, -1),
    light( 10736,  21152, -1, -2),
    light( 21255, -31419, -2,  3),
    light(-31308,  31669,  3, -3),
    light(-52386,  42186,  5, -4),
    light(-10314, -20912,  1,  2),
    light( 31766, -41938, -3,  4),
    light( 42273,  21149, -4, -2),
    light( 21255, -31419, -2,  3),
    light(-41860, -41934,  4,  4),
    light(-20817, -31421,  2,  3),
    light( 21231,  52695, -2, -5),
    light(-20793,  21151,  2, -2),
    light( 42274,  31671, -4, -3),
    light(-31353,  10636,  3, -1),
    light( 21235, -41937, -2,  4),
    light( 21251, -52452, -2,  5),
    light( 42289, -20905, -4,  2),
    light( 52766,  31666, -5, -3),
    light(-52357,  52701,  5, -5),
    light(-52386, -41935,  5,  4),
    light( 42260, -20913, -4,  2),
    light(-20836,  42180,  2, -4),
    light(-52386,  31670,  5, -3),
    light( 10757, -10390, -1,  1),
    light( 10752,  42183, -1, -4),
    light(-52381,  10633,  5, -1),
    light(-31332,  31667,  3, -3),
    light( 21237,  52701, -2, -5),
    light( 10731, -41934, -1,  4),
    light( 31787, -31425, -3,  3),
    light( 52757, -41943, -5,  4),
    light(-52374,  52698,  5, -5),
    light(-52338, -52456,  5,  5),
    light(-20844,  42178,  2, -4),
    light(-20825, -52456,  2,  5),
    light(-52367, -10389,  5,  1),
    light( 10744,  52697, -1, -5),
    light( 10704, -52457, -1,  5),
    light( 31766,  42186, -3, -4),
    light( 52761, -10390, -5,  1),
    light( 31777, -20904, -3,  2),
    light(-41818, -41938,  4,  4),
    light(-52370,  10637,  5, -1),
    light( 21267,  10639, -2, -1),
    light(-52382, -10394,  5,  1),
    light(-52370,  42180,  5, -4),
    light( 21223, -31428, -2,  3),
    light(-20845, -20913,  2,  2),
    light( 52812,  21148, -5, -2),
    light( 42241, -41935, -4,  4),
    light( 52814,  52696, -5, -5),
    light(-31316, -10398,  3,  1),
    light( 52776,  10636, -5, -1),
    light(-41823,  21148,  4, -2),
    light( 52788, -10391, -5,  1),
    light(-52370,  42186,  5, -4),
    light( 10721,  52701, -1, -5),
    light( 10744,  42185, -1, -4),
    light( 21219, -41939, -2,  4),
    light(-52378, -52451,  5,  5),
    light( 31758, -20911, -3,  2),
    light(-31332,  52697,  3, -5),
    light(-10329,  31671,  1, -3),
    light(-31308,  42179,  3, -4),
    light( 31726, -20911, -3,  2),
    light( 42275,  52701, -4, -5),
    light(-20829,  21149,  2, -2),
    light( 10706,  52696, -1, -5),
    light(-31312,  52701,  3, -5),
    light(-31364, -10397,  3,  1),
    light(-41855,  42179,  4, -4),
    light(-41823,  31665,  4, -3),
    light(-31362, -10389,  3,  1),
    light( 42273, -20912, -4,  2),
    light( 10700, -52453, -1,  5),
    light( 52788,  21149, -5, -2),
    light(-10324, -31424,  1,  3),
    light(-31356, -31423,  3,  3),
    light( 10725,  52701, -1, -5),
    light(-52343,  42186,  5, -4),
    light(-31324, -31425,  3,  3),
    light( 52799, -31419, -5,  3),
    light( 10716, -52458, -1,  5),
    light(-20849,  10638,  2, -1),
    light(-52378, -20905,  5,  2),
    light( 52764, -10391, -5,  1),
    light( 31726,  10635, -3, -1),
    light( 31750, -20907, -3,  2),
    light(-31344,  10636,  3, -1),
    light(-41839, -10397,  4,  1),
    light(-52333,  52701,  5, -5),
    light( 52780, -41939, -5,  4),
    light( 42242,  10641, -4, -1),
    light( 10728, -20909, -1,  2),
    light( 52780, -41943, -5,  4),
    light( 31766, -41939, -3,  4),
    light(-20846, -41934,  2,  4),
    light(-31303,  10640,  3, -1),
    light( 42282, -41934, -4,  4),
    light( 52780, -20907, -5,  2),
    light( 31726, -20908, -3,  2),
    light(-10310,  31666,  1, -3),
    light(-31316, -41940,  3,  4),
    light(-20801,  10635,  2, -1),
    light(-41859, -10396,  4,  1),
    light( 31750,  31669, -3, -3),
    light(-52370,  21151,  5, -2),
    light(-31312, -52449,  3,  5),
    light(-20821, -10389,  2,  1),
    light( 10744,  42179, -1, -4),
    light( 31766, -20909, -3,  2),
    light(-41870,  52692,  4, -5),
    light(-52366,  31671,  5, -3),
    light(-31364, -41938,  3,  4),
    light(-31324,  52700,  3, -5),
    light( 42289, -52449, -4,  5),
    light(-10298,  21156,  1, -2),
    light( 21212,  31662, -2, -3),
    light( 10696, -20907, -1,  2),
    light( 52776,  52699, -5, -5),
    light( 42261,  52697, -4, -5),
    light( 21235, -20905, -2,  2),
    light(-52334,  42181,  5, -4),
    light( 52777, -31428, -5,  3),
    light( 10716,  31665, -1, -3),
    light( 52817, -41943, -5,  4),
    light( 52798, -41934, -5,  4),
    light(-52338,  52696,  5, -5),
    light(-52338,  42178,  5, -4),
    light( 31787,  42186, -3, -4),
    light(-31356, -52454,  3,  5),
    light( 21259,  31667, -2, -3),
    light(-20807,  10641,  2, -1),
    light(-31319,  10641,  3, -1),
    light( 31746,  31667, -3, -3),
    light(-31324,  31671,  3, -3),
    light(-10278, -10398,  1,  1),
    light(-10286,  42181,  1, -4),
    light( 42257, -10390, -4,  1),
    light(-52354,  10641,  5, -1),
    light(-20845, -31423,  2,  3),
    light( 21220, -31424, -2,  3),
    light( 21230, -20904, -2,  2),
    light(-52392, -41934,  5,  4),
    light(-20793,  52694,  2, -5),
    light( 10744, -41941, -1,  4),
    light( 31758,  42185, -3, -4),
    light(-20788,  21149,  2, -2),
    light(-52346, -31428,  5,  3),
    light( 31729, -20908, -3,  2),
    light( 52804, -20909, -5,  2),
    light(-20841,  52697,  2, -5),
    light(-20820, -41934,  2,  4),
    light(-20829, -41936,  2,  4),
    light(-52375,  10632,  5, -1),
    light(-41874,  42184,  4, -4),
    light( 52756,  52700, -5, -5),
    light( 42265,  42184, -4, -4),
    light(-31364,  31668,  3, -3),
    light(-10310,  42178,  1, -4),
    light( 10716, -52454, -1,  5),
    light( 31774, -41937, -3,  4),
    light(-52389,  10638,  5, -1),
    light( 31747,  52692, -3, -5),
    light(-31316, -52457,  3,  5),
    light( 52760, -31423, -5,  3),
    light(-31305,  21151,  3, -2),
    light( 10736, -31421, -1,  3),
    light(-10326,  10634,  1, -1),
    light(-41847, -20905,  4,  2),
    light(-10286,  31666,  1, -3),
    light( 31787, -20906, -3,  2),
    light( 42290, -31419, -4,  3),
    light( 21223, -10394, -2,  1),
    light(-31306, -10394,  3,  1),
    light(-20801,  21149,  2, -2),
    light( 31753, -52449, -3,  5),
    light( 31787,  21151, -3, -2),
    light(-10314,  10634,  1, -1),
    light( 42284,  21156, -4, -2),
    light( 21235,  10632, -2, -1),
    light( 21228,  31671, -2, -3),
    light(-20825,  21147,  2, -2),
    light( 31758,  21153, -3, -2),
    light(-31305, -20909,  3,  2),
    light( 42241,  42184, -4, -4),
    light(-20801,  31663,  2, -3),
    light( 52796, -52453, -5,  5),
    light(-10334, -31423,  1,  3),
    light( 52764, -31425, -5,  3),
    light( 10720, -10393, -1,  1),
    light(-20844, -31422,  2,  3),
    light( 10704,  10635, -1, -1),
    light( 42250,  52696, -4, -5),
    light(-10273,  52695,  1, -5),
    light( 10698,  31662, -1, -3),
    light(-10278,  10638,  1, -1),
    light( 21211,  52693, -2, -5),
    light( 42298, -31424, -4,  3),
    light(-10326,  52701,  1, -5),
    light( 31760,  31671, -3, -3),
    light( 10752,  10641, -1, -1),
    light(-10313, -10398,  1,  1),
    light(-31311,  31671,  3, -3),
    light( 42273, -31422, -4,  3),
    light( 10720,  42184, -1, -4),
    light(-20845,  31670,  2, -3),
    light(-31347,  10641,  3, -1),
    light(-10332,  52692,  1, -5),
    light(-31332, -31419,  3,  3),
    light( 42293,  21156, -4, -2),
    light(-31353,  10632,  3, -1),
    light(-31316,  52699,  3, -5),
    light(-31364,  21149,  3, -2),
    light(-10278,  21156,  1, -2),
    light( 42302, -31427, -4,  3),
    light( 21219, -41942, -2,  4),
    light( 31731,  52701, -3, -5),
    light( 42241, -20909, -4,  2),
    light(-31344, -10397,  3,  1),
    light( 42277, -20904, -4,  2),
    light(-10274, -41939,  1,  4),
    light( 31782, -52450, -3,  5),
    light(-41876,  31667,  4, -3),
    light( 10749, -20904, -1,  2),
    light( 21224, -20911, -2,  2),
    light( 31734,  31662, -3, -3),
    light( 21231,  10635, -2, -1),
    light(-52389, -31419,  5,  3),
    light( 31734, -41937, -3,  4),
    light( 42257, -20905, -4,  2),
    light( 42297,  52697, -4, -5),
    light( 52805,  21156, -5, -2),
    light( 10709, -20910, -1,  2),
    light(-52370, -31420,  5,  3),
    light(-10326,  21152,  1, -2),
};
