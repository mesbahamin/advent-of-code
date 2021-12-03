#if 0
# Self-building c file. Invoke like: `./file.c`
outdir=out
input=$(basename "$0")
output="$outdir"/$(basename "$0" .c)
if [ "$input" -nt "$output" ];
then
    mkdir --parents "$outdir" || exit
    echo "Building ${output}." || exit
    clang -std=c11 -Wall -Wextra -pedantic -Wno-unused-function "$input" -o "$output" || exit
fi
if [ "$1" = "-r" ];
then
    ./"$output" "$@"
fi
exit
#endif

#include <errno.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

_Noreturn void assert_fail(const char *expr, const char *file, int line, const char *func) {
    fprintf(stderr, "%s:%d: %s: Assertion failed: '%s'\n", file, line, func, expr);
    abort();
}

#define AM_ENABLE_ASSERT 1
#define AM_ASSERT_FAIL(expr, file, line, func) assert_fail(expr, file, line, func)
#include "am_base.h"
#include "am_memory.h"
#include "am_list.h"
#include "am_string.h"

Str open_file(MemArena *arena, char *path) {
    FILE *f = fopen(path, "r");
    assert(f);

    s32 error = fseek(f, 0L, SEEK_END);
    assert(!error);

    s64 size = ftell(f);
    assert(size >= 0);
    rewind(f);

    u8 *buf = am_mem_arena_push(arena, size);
    assert(buf);

    size_t items_read = fread(buf, 1, size, f);
    assert(items_read == (size_t)size);

    error = fclose(f);
    assert(!error);

    return am_str(buf, size);
}

int main(void) {
    MemArena a = am_mem_arena_create(am_mem_base_allocator_malloc());
    Str input = open_file(&a, "day03_input.txt");
    StrList lines = am_str_split(&a, input, (u8 *)"\n", 1);

    u64 num_columns = lines.first->s.size;
    u64 *counts = AM_MEM_ARENA_PUSH_ARRAY(&a, u64, num_columns);
    for (u64 i = 0; i < num_columns; i++) {
        counts[i] = 0;
    }

    for (StrListNode *number = lines.first; number; number = number->next) {
        assert(number->s.size == num_columns);
        for (u64 i = 0; i < num_columns; i++) {
            counts[i] += number->s.str[i] == '1';
        }
    }

    u64 num_numbers = lines.node_count;
    assert(num_numbers % 2 == 0);
    u64 gamma = 0;
    for (u64 i = 0; i < num_columns; i++) {
        assert(counts[i] != num_numbers / 2);
        gamma |= (counts[i] > (num_numbers / 2)) << (num_columns - i - 1);
    }

    u64 epsilon = (~gamma) & (0xFFFFFFFF >> (64 - num_columns));

    printf("Power consumption: %" PRIu64 "\n", gamma * epsilon);
    am_mem_arena_release(&a);
    return 0;
}
