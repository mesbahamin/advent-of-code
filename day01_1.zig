const std = @import("std");
const dbg = std.debug;

pub fn main() void {
    var fuel_for_module_mass: i32 = 0;
    var fuel_for_total_mass: i32 = 0;
    for (input) |mass| {
        var module_mass_fuel = get_fuel(mass);
        var total_fuel = get_total_module_fuel(mass);
        fuel_for_module_mass += module_mass_fuel;
        fuel_for_total_mass += total_fuel;
    }
    dbg.warn("01-1 Total fuel for the modules: {}\n", fuel_for_module_mass);
    dbg.warn("01-2 Total fuel for the modules and fuel: {}\n", fuel_for_total_mass);
}

fn get_fuel(mass: i32) i32 {
    return @divFloor(mass, 3) - 2;
}

test "get fuel" {
    dbg.assert(get_fuel(12) == 2);
    dbg.assert(get_fuel(14) == 2);
    dbg.assert(get_fuel(1969) == 654);
    dbg.assert(get_fuel(100756) == 33583);
}

fn get_total_module_fuel(module_mass: i32) i32 {
    const module_fuel_mass = get_fuel(module_mass);
    var unfueled_fuel = module_fuel_mass;
    var fuel_fuel_mass: i32 = 0;
    while (unfueled_fuel > 0) {
        // "fuel" is a really strange word
        var fuel_for_fuel = get_fuel(unfueled_fuel);
        if (fuel_for_fuel <= 0) {
            break;
        }
        fuel_fuel_mass += fuel_for_fuel;
        unfueled_fuel = fuel_for_fuel;
    }
    return module_fuel_mass + fuel_fuel_mass;
}

test "get total module fuel" {
    dbg.assert(get_total_module_fuel(14) == 2);
    dbg.assert(get_total_module_fuel(1969) == 966);
    dbg.assert(get_total_module_fuel(100756) == 50346);
}

const input = [_]i32{
    91617,
    134652,
    101448,
    83076,
    53032,
    80487,
    106061,
    103085,
    71513,
    143874,
    102830,
    121433,
    139937,
    104468,
    53098,
    75999,
    113915,
    73992,
    90028,
    64164,
    101248,
    111333,
    89201,
    89076,
    129360,
    81573,
    54381,
    64105,
    104272,
    144188,
    81022,
    125558,
    87910,
    135654,
    110929,
    131610,
    147160,
    139648,
    118129,
    93967,
    123117,
    77927,
    112034,
    84847,
    145527,
    72652,
    123043,
    136324,
    71228,
    118583,
    56992,
    141812,
    60119,
    105185,
    97653,
    134563,
    54195,
    64473,
    75606,
    148515,
    88765,
    112562,
    52156,
    119805,
    117149,
    149791,
    128964,
    108955,
    55806,
    86025,
    148350,
    74382,
    73632,
    141124,
    101688,
    106829,
    132594,
    113645,
    90320,
    104874,
    95210,
    118499,
    56445,
    86371,
    113833,
    122860,
    112507,
    55964,
    105993,
    92005,
    83760,
    90258,
    56238,
    127426,
    147641,
    129484,
    107162,
    99535,
    107975,
    136238,
};
