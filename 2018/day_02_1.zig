const std = @import("std");
const debug = std.debug;

pub fn main() void {
    var result = checksum(input_02);
    debug.assert(result == 4712);
    debug.warn("02-1: {}\n", result);
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
