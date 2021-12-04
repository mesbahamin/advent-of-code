#ifndef AM_STRING_H
#define AM_STRING_H

#ifndef AM_MEMORY_H
    #error "am_memory.h is required"
#endif
#ifndef AM_LIST_H
    #error "am_list.h is required"
#endif

typedef struct {
    usz size;
    u8 *str;
} Str;

typedef struct StrListNode StrListNode;
struct StrListNode {
    StrListNode *next;
    Str s;
};

typedef struct {
    StrListNode *first;
    StrListNode *last;
    u64 node_count;
    u64 total_size;
} StrList;

#define AM_STR_LIT(s) (Str) { .str = (u8 *)(s), .size = sizeof(s) - 1, }
#define AM_STR_EXPAND(s) (s32)((s).size), ((s).str)

internal usz am_cstr_len(char *cstr) {
    usz len = 0;
    while (cstr && *cstr != '\0') {
        len++;
        cstr++;
    }
    return len;
}

internal Str am_str(u8 *str, usz size) {
    return (Str) { .size = size, .str = str, };
}

internal Str am_str_from_range(u8 *start, u8 *opl) {
    assert(start < opl);
    return am_str(start, opl - start);
}

internal Str am_str_from_cstr(char *cstr, usz len) {
    return am_str((u8 *)cstr, len);
}

// TODO: Use string interning
internal bool am_str_eq(Str s1, Str s2) {
    if (s1.size != s2.size) {
        return false;
    }

    for (usz i = 0; i < s1.size; i++) {
        if (s1.str[i] != s2.str[i]) {
            return false;
        }
    }

    return true;
}

internal bool am_cstr_eq(char *cstr1, char *cstr2) {
    usz len1 = am_cstr_len(cstr1);
    usz len2 = am_cstr_len(cstr2);
    return am_str_eq(am_str_from_cstr(cstr1, len1), am_str_from_cstr(cstr2, len2));
}

internal Str am_str_line(Str s, u8 *cursor) {
    u8 *opl = s.str + s.size;

    assert(cursor >= s.str && cursor < opl);

    u8 *end = cursor;
    while (end < opl) {
        if (*end == '\n') {
            break;
        }
        end++;
    }

    u8 *beginning = cursor - (*cursor == '\n');
    while (beginning >= s.str) {
        if (*beginning == '\n') {
            beginning++;
            break;
        }
        beginning--;
    }

    return am_str_from_range(beginning, end);
}

internal bool am_str_contains(Str s, char c) {
    for (usz i = 0; i < s.size; i++) {
        if (s.str[i] == c) {
            return true;
        }
    }
    return false;
}

internal bool am_cstr_contains(char *s, usz len, char c) {
    return am_str_contains(am_str_from_cstr(s, len), c);
}

internal bool am_str_cstr_eq(Str s, char *cstr) {
    return am_str_eq(s, am_str_from_cstr(cstr, am_cstr_len(cstr)));
}

internal void am_str_list_append(MemArena *arena, StrList *list, Str s) {
    StrListNode *node = am_mem_arena_push(arena, sizeof(StrListNode));
    *node = (StrListNode) {
        .s = s,
    };
    SLL_QUEUE_PUSH(list->first, list->last, node);
    list->node_count += 1;
    list->total_size += s.size;
}

typedef struct {
    Str pre;
    Str mid;
    Str post;
} StringJoinOptions;

internal Str am_str_join(MemArena *arena, StrList *list, StringJoinOptions *options) {
    StringJoinOptions join;
    if (options) {
        join = *options;
    } else {
        join = (StringJoinOptions){0};
    }

    u64 total_size = list->total_size
        + join.pre.size
        + (join.mid.size * (list->node_count - 1))
        + join.post.size;

    Str s= {
        .str = AM_MEM_ARENA_PUSH_ARRAY(arena, u8, total_size),
        .size = total_size,
    };

    u8 *p = s.str;
    am_mem_copy(p, join.pre.str, join.pre.size);
    p += join.pre.size;

    bool is_mid = false;
    for (StrListNode *n = list->first; n; n = n->next) {
        if (is_mid) {
            am_mem_copy(p, join.mid.str, join.mid.size);
            p += join.mid.size;
        }

        am_mem_copy(p, n->s.str, n->s.size);
        p += n->s.size;

        is_mid = true;
    }

    am_mem_copy(p, join.post.str, join.post.size);
    p += join.post.size;

    return s;
}

internal StrList am_str_split(MemArena *arena, Str s, u8 *split_chars, u64 split_char_count) {
    StrList list = {0};

    u8 *cursor = s.str;
    u8 *split_beginning = cursor;
    u8 *opl = s.str + s.size;
    while (cursor < opl) {
        bool split_byte = false;
        for (u64 i = 0; i < split_char_count; i++) {
            if (split_chars[i] == *cursor) {
                split_byte = true;
                break;
            }
        }

        if (split_byte) {
            if (split_beginning < cursor) {
                am_str_list_append(arena, &list, am_str_from_range(split_beginning, cursor));
            }
            split_beginning = cursor + 1;
        }
        cursor++;
    }

    if (split_beginning < cursor) {
        am_str_list_append(arena, &list, am_str_from_range(split_beginning, cursor));
    }

    return list;
}

#if defined(AM_INCLUDE_TESTS)
internal void am_string_test(void) {
    assert(am_cstr_len("abcdefg") == 7);
    assert(am_cstr_len("") == 0);
    assert(am_cstr_len("\0") == 0);
    assert(am_cstr_eq("", ""));
    assert(am_cstr_eq("\0", "\0"));
    assert(am_cstr_eq("abc", "abc"));
    assert(!am_cstr_eq("ABC", "abc"));
    assert(!am_cstr_eq("", " "));
    assert(!am_cstr_eq("abc", "abcde"));
    assert(!am_str_cstr_eq(AM_STR_LIT("abcd"), "abc"));
    assert(am_str_cstr_eq(AM_STR_LIT("abc"), "abc"));
    assert(am_cstr_contains("abc", 3, 'c'));
    assert(am_cstr_contains("a c", 3, ' '));
    assert(am_cstr_contains("", 1, '\0'));
    assert(!am_cstr_contains("abc", 3, 'z'));
    assert(!am_cstr_contains("", 0, 'z'));
    assert(!am_cstr_contains("", 0, '\0'));
    assert(am_cstr_contains("https://www.example.com", 23, '/'));

    {
        StrList l = {0};
        MemArena a = am_mem_arena_create(am_mem_base_allocator_malloc());
        Str strings[] = {
            AM_STR_LIT("one"),
            AM_STR_LIT("two"),
            AM_STR_LIT("three"),
        };

        for (u64 i = 0; i < ARRAY_COUNT(strings); i++) {
            am_str_list_append(&a, &l, strings[i]);
        }

        Str joined = am_str_join(&a, &l, &(StringJoinOptions){
            .pre = AM_STR_LIT("Joined: '"),
            .mid = AM_STR_LIT(", "),
            .post = AM_STR_LIT("'."),
        });

        printf("%.*s\n", AM_STR_EXPAND(joined));

        StrList split = am_str_split(&a, AM_STR_LIT(", one, two, three, "), (u8 *)", ", 2);

        for (StrListNode *n = split.first; n; n = n->next) {
            printf("split: '%.*s'\n", AM_STR_EXPAND(n->s));
        }
        am_mem_arena_release(&a);
    }
}
#endif // defined(AM_INCLUDE_TESTS)

#endif // AM_STRING_H
