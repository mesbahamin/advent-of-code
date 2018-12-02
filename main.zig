const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const os = std.os;

pub fn main() !void {
    var allocator = &std.heap.DirectAllocator.init().allocator;
    var input01 = try get_file_contents(allocator, "input_01.txt");
    defer allocator.free(input01);

    debug.warn("01-1: {}\n", total_sum(input01));
    debug.warn("01-2: {}\n", first_visited_twice(input01));
    debug.warn("02-1: {}\n", checksum(input_02));
    common_chars(input_02);
}

fn common_chars(ids: [] const [] const u8) void {
    for (ids) |id, i| {
        outer: for (ids[i + 1..]) |id2, j| {
            if (i != j) {
                debug.assert(id.len == id2.len);
                var distance: u32 = 0;
                for (id) |char, k| {
                    if (char != id2[k]) {
                        distance += 1;
                    }
                    if (distance > 1) {
                        continue :outer;
                    }
                }
                if (distance == 1) {
                    //debug.warn("{}\n", id);
                    //debug.warn("{}\n", id2);
                    for (id) |char, x| {
                        if (char == id2[x]) {
                            debug.warn("{c}", char);
                        }
                    }
                    debug.warn("\n");

                    break;
                }
            }
        }
    }
}

test "common chars" {
    const ids = [] const [] const u8 {
        "abcde",
        "fghij",
        "klmno",
        "pqrst",
        "fguij",
        "axcye",
        "wvxyz",
    };
    common_chars(ids);
}

fn checksum(input: [] const [] const u8) u32{
    var num_with_pair: u32 = 0;
    var num_with_triple : u32 = 0;
    for (input) |id| {
        if (has_pair(id)) {
            num_with_pair += 1;
        }
        if (has_triple(id)) {
            num_with_triple += 1;
        }
    }

    return num_with_pair * num_with_triple;
}

fn has_pair(id: [] const u8) bool {
    // ASCII: [ 65, 66, ..., 122 ]
    const ascii_range = u8('z' - 'A') + 1;
    var counts = []u32{0} ** ascii_range;
    for (id) |char| {
        var count_index: u8 = u8(char - 'A');
        debug.assert(count_index < counts.len);
        counts[count_index] += 1;
    }
    for (counts) |count| {
        if (count == 2) {
            return true;
        }
    }
    return false;
}

fn has_triple(id: [] const u8) bool {
    // ASCII: [ 65, 66, ..., 122 ]
    const ascii_range = u8('z' - 'A') + 1;
    var counts = []u32{0} ** ascii_range;
    for (id) |char| {
        var count_index: u8 = u8(char - 'A');
        debug.assert(count_index < counts.len);
        counts[count_index] += 1;
    }
    for (counts) |count| {
        if (count == 3) {
            return true;
        }
    }
    return false;
}

test "letter dups" {
    debug.assert(!has_pair("abcdef"));
    debug.assert(!has_triple("abcdef"));

    debug.assert(has_pair("bababc"));
    debug.assert(has_triple("bababc"));

    debug.assert(has_pair("abbcde"));
    debug.assert(!has_triple("abbcde"));

    debug.assert(!has_pair("abcccd"));
    debug.assert(has_triple("abcccd"));

    debug.assert(has_pair("aabcdd"));
    debug.assert(!has_triple("aabcdd"));

    debug.assert(has_pair("abcdee"));
    debug.assert(!has_triple("abcdee"));

    debug.assert(!has_pair("ababab"));
    debug.assert(has_triple("ababab"));
}

fn total_sum(input: []const u8) !i32 {
    var sum: i32 = 0;
    var index: usize = 0;
    while (index < input.len) {
        var e = index;
        while (input[e] != '\n') {
            e += 1;
        }
        debug.assert('\n' == input[e]);

        var num = try fmt.parseInt(i32, input[index..e], 10);
        sum += num;
        index = e + 1;
    }
    return sum;
}

test "total_sum" {
    const s: []const u8 = "-2\n-3\n+4\n-15\n-15\n+18\n-7\n+11\n-16\n-134\n+200\n";
    debug.assert(41 == try total_sum(s));
}

fn first_visited_twice(input: []const u8) !i32 {
    var sum: i32 = 0;
    var index: usize = 0;

    const visited_magnitude: usize = 1000000;
    const visited_size: usize = (visited_magnitude * 2) + 1;
    // [ -visited_magnitude, ..., -3, -2, -1, 0, 1, 2, 3, ..., visited_magnitude ]
    var visited = []bool{false} ** visited_size;

    //debug.warn("{} ", sum);
    while (true) {
        var visited_index = @intCast(usize, @intCast(i32, visited_magnitude) + sum);
        debug.assert(visited_index >= 0);
        if (visited[visited_index] == true) {
            return sum;
        } else {
            visited[visited_index] = true;
        }

        var e = index;
        while (input[e] != '\n') {
            e += 1;
        }
        debug.assert('\n' == input[e]);

        var num = try fmt.parseInt(i32, input[index..e], 10);
        sum += num;
        //debug.warn("+ {}\n", num);
        //debug.warn("{} ", sum);
        index = (e + 1) % input.len;
    }
    debug.warn("\n---\n");
    return sum;
}

test "first_visited_twice" {
    debug.assert(0 == try first_visited_twice("+1\n-1\n"));
    debug.assert(10 == try first_visited_twice("+3\n+3\n+4\n-2\n-4\n"));
    debug.assert(5 == try first_visited_twice("-6\n+3\n+8\n+5\n-6\n"));
    debug.assert(14 == try first_visited_twice("+7\n+7\n-2\n-7\n-4\n"));
}

fn get_file_contents(allocator: *mem.Allocator, file_name: []const u8) ![]u8 {
    var file = try os.File.openRead(file_name);
    defer file.close();

    const file_size = try file.getEndPos();

    var file_in_stream = io.FileInStream.init(file);
    var buf_stream = io.BufferedInStream(io.FileInStream.Error).init(&file_in_stream.stream);
    const st = &buf_stream.stream;
    return try st.readAllAlloc(allocator, 2 * file_size);
}

const input_02 = [] const [] const u8 {
    "luojygedpvsthptkxiwnaorzmq",
    "lucjqgedppsbhftkxiwnaorlmq",
    "lucjmgefpvsbhftkxiwnaorziq",
    "lucjvgedpvsbxftkxiwpaorzmq",
    "lrcjygedjvmbhftkxiwnaorzmq",
    "lucjygedpvsbhftkxiwnootzmu",
    "eucjygedpvsbhftbxiwnaorzfq",
    "lulnygedpvsbhftkxrwnaorzmq",
    "lucsygedpvsohftkxqwnaorzmq",
    "lucjyaedpvsnhftkxiwnaorzyq",
    "lunjygedpvsohftkxiwnaorzmb",
    "lucjxgedpvsbhrtkxiwnamrzmq",
    "lucjygevpvsbhftkxcwnaorzma",
    "lucjbgedpvsbhftrxiwnaoazmq",
    "llcjygkdpvhbhftkxiwnaorzmq",
    "lmcjygxdpvsbhftkxswnaorzmq",
    "lucpygedpvsbhftkxiwraorzmc",
    "lucjbgrdpvsblftkxiwnaorzmq",
    "lucjfgedpvsbhftkxiwnaurzmv",
    "lucjygenpvsbhytkxiwnaorgmq",
    "luqjyredsvsbhftkxiwnaorzmq",
    "lucjygedpvavhftkxiwnaorumq",
    "gucjygedpvsbhkxkxiwnaorzmq",
    "lucjygedpvsbhftkxlwnaordcq",
    "lucjygedpvibhfqkxiwnaorzmm",
    "lucjegedpvsbaftkxewnaorzmq",
    "kucjygeqpvsbhfokxiwnaorzmq",
    "lugjygedwvsbhftkxiwnatrzmq",
    "lucjygedqvsbhftdxiwnayrzmq",
    "lucjygekpvsbuftkxiwnaqrzmq",
    "lucjygedpvsbhfbkxiwnaoozdq",
    "lscjygedpvzchftkxiwnaorzmq",
    "luckygedpvsbxftkxiwnaorvmq",
    "luyjygedgvsbhptkxiwnaorzmq",
    "lmcjygedpvsbhfckxiwnaodzmq",
    "lucmygedwvybhftkxiwnaorzmq",
    "lgcjhgedavsbhftkxiwnaorzmq",
    "lucjugedpvsbhftkxiwmaoozmq",
    "lucjygedpvybhftkxkwnaorumq",
    "lucjygedpvzbhfakxiwnaorzpq",
    "lucjygedpvsbhftyxzwnajrzmq",
    "lucjygedpvsdhfakxiwnoorzmq",
    "luyjygeopvhbhftkxiwnaorzmq",
    "lucjygadpvsbhntkxiwnaorzmx",
    "lucjygedzvsbhftkiiwuaorzmq",
    "sucjygodpvsbhftkxiwuaorzmq",
    "euijygydpvsbhftkxiwnaorzmq",
    "lucjlgeduvsbhftkxicnaorzmq",
    "lucjdgedpvsbhfgkxiwnhorzmq",
    "lucjymedpvsbhotkxiqnaorzmq",
    "lucjygmdpvsbhftkxywnairzmq",
    "lucjggedpvsbhfxkxiqnaorzmq",
    "sucjygedpvsbhftkxiwnaorjmv",
    "lucjlgedpvsbhftkxiwnairzmg",
    "lucjygedppubhftkxijnaorzmq",
    "lucjyxedpvsvhftkxlwnaorzmq",
    "lucjygedpvxbhftkfiwyaorzmq",
    "lucjygedposbhftkniwnaorzmw",
    "lucjygewpvsbhftgxiwnavrzmq",
    "lucjynedpvsbmftkaiwnaorzmq",
    "lucjyhedpvzbhftkxiwncorzmq",
    "lucjygedpvsbhfikpiwnaoezmq",
    "lupjypedpvsbhftkjiwnaorzmq",
    "lucjygudpvsbhfwkxivnaorzmq",
    "lucjygrdpvsbhatkxzwnaorzmq",
    "lucjbgmdpvsbhftkxihnaorzmq",
    "lucjmgedpvpbhftkxiwnaorcmq",
    "lucjygedpvskhfukmiwnaorzmq",
    "lucjygedgvsbhftkxiwnvprzmq",
    "lucjzgedppsbhytkxiwnaorzmq",
    "lfcjypedpvsbhftrxiwnaorzmq",
    "lucjyqldphsbhftkxiwnaorzmq",
    "lucjygedpvsbhftzxewnaorzqq",
    "lucjygeapvsbhftkxiinoorzmq",
    "lucjygedpvszhftguiwnaorzmq",
    "luojygedpvsbhftkxawnaornmq",
    "lucjygedpcsboetkxiwnaorzmq",
    "lufjygedpvfbhftaxiwnaorzmq",
    "luciygedpvsbhftkxhwaaorzmq",
    "lucjygedpvnbhftkaiwnaorzmc",
    "lucjygedpvsbhftkxiwcaorbdq",
    "lucjygelpvsbhftaxiwsaorzmq",
    "lujjygedpssbhftkxiwnaorzmr",
    "ludjygedpvsbhftkxiynaorzmj",
    "lukjygeedvsbhftkxiwnaorzmq",
    "lucjqpedpvsbhftkxiwnaozzmq",
    "jucjygedpvsbhftkxgwnaorqmq",
    "llwjygedpvsbhetkxiwnaorzmq",
    "rucjygedpvsbhftkxiwndorymq",
    "lucjygedpvsbhftvxswnaorwmq",
    "lucjygerpvsbhfykxiwnaormmq",
    "lucjynedpvsbhftkxijnaorziq",
    "ljcjygedpvrbhftkeiwnaorzmq",
    "lucjygedpnsbhftkxiwhaornmq",
    "lucjygadpvsbhftkxibnaorzqq",
    "lucjqgedpvsihftkxiwnaorzdq",
    "lucjygedpvsqhfttjiwnaorzmq",
    "llcjygedsvsbhftkxiwwaorzmq",
    "lfckygedpvsbhftkxiunaorzmq",
    "lucjyeedpdsbhftkxiwnaotzmq",
    "lucjygedpvsbhftkoiwnaoqzcq",
    "huwjvgedpvsbhftkxiwnaorzmq",
    "lucjygldpvsbdhtkxiwnaorzmq",
    "lycxygedpvsbhftmxiwnaorzmq",
    "lucjygedpvsbhftyxianvorzmq",
    "lucuygedpdsbhqtkxiwnaorzmq",
    "lucjyggdpvsbhftkxiwnavremq",
    "lucjyggdpvsbkftkxiwnaorbmq",
    "luchyqedpvsbhftixiwnaorzmq",
    "lpcnygedpvsbhftkxzwnaorzmq",
    "lucjygedpvsihftkxiwfaortmq",
    "lucjygvdpvsbhgtkxiwnamrzmq",
    "lucjygodpvrbhqtkxiwnaorzmq",
    "lucjygedpfsbhftkxipnaorzma",
    "lucjygedpvsbhftkxpcjaorzmq",
    "lucjygodbmsbhftkxiwnaorzmq",
    "lucjygedpvsbhftkxipnaogzmb",
    "luxjygjdpvsbhltkxiwnaorzmq",
    "lucxygedpvsbhftkxzwnaorjmq",
    "luajygedpvsbhftzxiwaaorzmq",
    "lhcjygedpvsqhftfxiwnaorzmq",
    "lucjygecphsbhftkxiwnaprzmq",
    "lucjygedpvsbhptkxifnaorqmq",
    "lucjygedpvichftkpiwnaorzmq",
    "lucjygedpcsbhstkxswnaorzmq",
    "kucjygedpvsbhftkxiwbyorzmq",
    "lfpjxgedpvsbhftkxiwnaorzmq",
    "lucjytldpvsbhftkxiwdaorzmq",
    "lufjygedpvfbhftbxiwnaorzmq",
    "lucjygebpvgbhftkxipnaorzmq",
    "luujygedpvdbhftkxiwnaorzmd",
    "lucjygedpvsbhfbyxwwnaorzmq",
    "lucjygedpvsbhftkxiwnaoqpmw",
    "qucgygedpvsbhftkxiwnaortmq",
    "ludjtgedpvsbhftkxiunaorzmq",
    "lucjyiedovsbhftkxiwjaorzmq",
    "lucjygedpysbjftoxiwnaorzmq",
    "lumjygedpvsbuftkxiknaorzmq",
    "lucjygedpvsbhfokxgonaorzmq",
    "lucjygeqpvsbhftkfiwnaorzeq",
    "lucjygedpvskhftkxiwntorkmq",
    "luujygedpvsbhftkxiwraorzmt",
    "lucwygedpvsbjftkxiwnaorzmj",
    "jucjyfedcvsbhftkxiwnaorzmq",
    "luujygedpnsehftkxiwnaorzmq",
    "lucjygedpvszhfckxiwnaorzmi",
    "lucjyredpvsbzftkpiwnaorzmq",
    "lucjygedpvsbwfgkxiwnaorzoq",
    "lucjygedpvgbhftkpiwnaorzms",
    "lucjygedpvjbhftkxzwnaoizmq",
    "vucjycedpvsbhftkxiwfaorzmq",
    "luawygeapvsbhftkxiwnaorzmq",
    "lucjygetpvsbhftkxiwnaafzmq",
    "lucjvgedpvsbhftkxywnavrzmq",
    "luolygedpvsbgftkxiwnaorzmq",
    "likjygedpvsbhftkxiwnabrzmq",
    "lucjygedovsbhftkxirpaorzmq",
    "lucjygedphsshftkxqwnaorzmq",
    "uuqjygewpvsbhftkxiwnaorzmq",
    "lucjygedcvsbhftkxiwoarrzmq",
    "lucnygedpvsbhfakxiwnaorzms",
    "lucjygedpvsbhntkxiwnawrzmb",
    "lucjygedpvsblfxkxivnaorzmq",
    "lucjygedpvsghftkxiwnaawzmq",
    "yucjygedpgsbhftkxiwnaorzbq",
    "lucjyweapvsbhftkxiwnaoezmq",
    "lucjygevpvsbyftcxiwnaorzmq",
    "luejygedovsbhftkxiwnqorzmq",
    "lucjyqedpvsbhfbkxiwnaorzms",
    "lucjypedpvsbhftwxiwnhorzmq",
    "lucjygedpvsbhmtkviwxaorzmq",
    "lucjogedpvpbhftkxiwnaorqmq",
    "lucjygedpvsbhztkxkwnaoazmq",
    "lucjyaedpvsbcftkxiwnaorzhq",
    "lucjygbdpvkbhftkxiznaorzmq",
    "lucpygedpvzbhftkxfwnaorzmq",
    "lucjmgedpcsbhftkxiwnaoezmq",
    "lucjygedyvsbbftkxiwnnorzmq",
    "lucjyyedpvsbhftuxiwnaonzmq",
    "lucjygfdpvsbhutkxiwnaorzmt",
    "uccjygedpvschftkxiwnaorzmq",
    "lusjygedpvbbhqtkxiwnaorzmq",
    "ducuygedpvsbhftkxiwnaorzyq",
    "lucjygkdvwsbhftkxiwnaorzmq",
    "cucjyyedpvsbhftkxiwnaerzmq",
    "lucjygedavsbhftkxiwnkorzbq",
    "lucjygedmvsyhftkxiwiaorzmq",
    "lucjygeipvsbhfpkxiwnaorzpq",
    "vucjugedvvsbhftkxiwnaorzmq",
    "lucjyzedpvsbhftkxpwnaoozmq",
    "lucjygedpvgbhftkxiwtaorzqq",
    "lecjygedpvcwhftkxiwnaorzmq",
    "lucjyghdpvsbhfcyxiwnaorzmq",
    "lucjygedpvesqftkxiwnaorzmq",
    "lucjyjehpvsbhftbxiwnaorzmq",
    "lucjygedpvtbhdtkxignaorzmq",
    "lucjygxdpgsbhftkxivnaorzmq",
    "lucjygvdpvsbhftkpiwnaorzqq",
    "lucjysedpvsbhftkxiwnalrzmc",
    "lucjygedpvkbhjtkxiwnaorsmq",
    "lucjygedpvsbvfgkxiwnaerzmq",
    "lucjygedpvsihftkxilnaorzmu",
    "lvcvygndpvsbhftkxiwnaorzmq",
    "lucjysedpqsbhftkxiwnaordmq",
    "lucsygeypvsbhftkwiwnaorzmq",
    "lucjygewpotbhftkxiwnaorzmq",
    "lucjysedpvsbhftkxiwnanrzmv",
    "lucjygedpvsbhutkxiwnaoplmq",
    "wucjygedpvsqbftkxiwnaorzmq",
    "lacjygeepvsbhftkxiwnjorzmq",
    "lucjygedpusyhftkxicnaorzmq",
    "qucjyredpvsbhftkxiwnworzmq",
    "lucjygedevsbhftkgiwnayrzmq",
    "lucjygedpksbrftkliwnaorzmq",
    "lucjygedpvsbhfgkxisnaorzeq",
    "lucjygedpvhdhftkeiwnaorzmq",
    "lucjsgedpvsboftkxiwnaorumq",
    "luctygedpvsbhftouiwnaorzmq",
    "lucjygedpvsjhfukjiwnaorzmq",
    "lucjagrepvsbhftkxiwnaorzmq",
    "lucjkgerpvsbhftkxiwnairzmq",
    "turjygedpvsbnftkxiwnaorzmq",
    "lbcjygedpvsbhftkdpwnaorzmq",
    "lucpygedpvsbhftkxnwnoorzmq",
    "jucjygedpvsbhbtkxicnaorzmq",
    "lecjygedpvsbhftkriwnaogzmq",
    "licjyvcdpvsbhftkxiwnaorzmq",
    "lrcjygewpnsbhftkxiwnaorzmq",
    "ltcxygedpvlbhftkxiwnaorzmq",
    "luctygedpvhbhztkxiwnaorzmq",
    "lucwygedplsbhfakxiwnaorzmq",
    "lucjygedpnsbhftkxiwjaoezmq",
    "lucpygedptsbhftkxiwnaorzmo",
    "lucjygedpvibhqtkxiknaorzmq",
    "lucjwgqdpvrbhftkxiwnaorzmq",
    "lucjmgkdpvsbhftkxiwraorzmq",
    "lucjygwupvsbhftkxiznaorzmq",
    "lucjhgedpvobhftkxiwncorzmq",
    "lucjygedpvsbhftkxiwnaohtmj",
    "lucjygedpvsbeftkfiwnaorzyq",
    "lucjygcdpvsbpftkhiwnaorzmq",
    "lucjygedpmsbhftkxiwnkouzmq",
    "oucjygedpvsbyftkximnaorzmq",
    "lucjcgedpvsbhftkxywnforzmq",
    "lfcjygedfvsbdftkxiwnaorzmq",
    "ducjygedevsbhfttxiwnaorzmq",
    "ldcjdgedpvsbhftkxiwnavrzmq",
    "lucjymedmvsbhqtkxiwnaorzmq",
    "lucjygedpvabhftkxiwnasrlmq",
    "lucjygefpvsbhftkxmwnaorkmq",
};
