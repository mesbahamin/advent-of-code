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

#include <inttypes.h>
#include <errno.h>
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
    Str input = open_file(&a, "day01_input.txt");
    StrList lines = am_str_split(&a, input, (u8 *)"\n", 1);
    u64 increase_count = 0;
    u64 previous_number = UINT64_MAX;
    for (StrListNode *line = lines.first; line; line = line->next) {
        u64 number = 0;
        for (usz i = 0; i < line->s.size; i++) {
            u64 digit = line->s.str[i] - '0';
            number = (number * 10) + digit;
        }
        increase_count += (number > previous_number);
        previous_number = number;
    }
    printf("Increase Count: %" PRIu64 "\n", increase_count);
    am_mem_arena_release(&a);
    return 0;
}
