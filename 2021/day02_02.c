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
    Str input = open_file(&a, "day02_input.txt");
    StrList tokens = am_str_split(&a, input, (u8 *)"\n ", 2);

    struct {
        s64 horizontal;
        s64 depth;
        s64 aim;
    } position = {0};

    s64 *dimension = NULL;
    s64 sign = 0;
    bool expect_command = true;

    for (StrListNode *token = tokens.first; token; token = token->next) {
        if (expect_command) {
            if (am_str_eq(token->s, AM_STR_LIT("forward"))) {
                dimension = &position.horizontal;
                sign = 1;
            } else if (am_str_eq(token->s, AM_STR_LIT("up"))) {
                dimension = &position.aim;
                sign = -1;
            } else if (am_str_eq(token->s, AM_STR_LIT("down"))) {
                dimension = &position.aim;
                sign = 1;
            } else {
                assert(false);
            }
            expect_command = false;
        } else {
            assert(dimension);
            assert(sign == -1 || sign == 1);
            assert(token->s.size == 1);
            assert(token->s.str[0] >= '0' && token->s.str[0] <= '9');
            s64 amount = token->s.str[0] - '0';
            *dimension += sign * amount;
            if (dimension == &position.horizontal) {
                position.depth += position.aim * amount;
            }
            expect_command = true;
        }
    }

    printf("Multiplied position dimensions: %" PRId64 "\n", position.horizontal * position.depth);

    am_mem_arena_release(&a);
    return 0;
}
