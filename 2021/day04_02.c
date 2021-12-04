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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

int compare_u64(const void *a, const void *b) {
    u64 num_a = *((u64 *)a);
    u64 num_b = *((u64 *)b);
    if (num_a == num_b) {
        return 0;
    } else if (num_a < num_b) {
        return -1;
    } else {
        return 1;
    }
}

s64 parse_number(Str s) {
    s64 number = 0;
    for (u64 i = 0; i < s.size; i++) {
        assert(s.str[i] >= '0' && s.str[i] <= '9');
        number = (number * 10) + (s.str[i] - '0');
    }
    return number;
}

int main(void) {
    MemArena a = am_mem_arena_create(am_mem_base_allocator_malloc());
    Str input = open_file(&a, "day04_input.txt");

    StrList split_data = am_str_split(&a, input, (u8 *)"\n ", 2);
    StrList split_first_line = am_str_split(&a, split_data.first->s, (u8 *)",", 1);

    u64 drawn_number_count = split_first_line.node_count;
    u64 board_number_count = split_data.node_count - 1;
    assert(board_number_count % 25 == 0);

    s64 *drawn_numbers = AM_MEM_ARENA_PUSH_ARRAY(&a, s64, drawn_number_count);
    s64 *board_numbers = AM_MEM_ARENA_PUSH_ARRAY(&a, s64, board_number_count);

    {
        u64 i = 0;
        for (StrListNode *number = split_first_line.first; number; number = number->next) {
            drawn_numbers[i] = parse_number(number->s);
            i++;
        }
        assert(i == drawn_number_count);
    }

    {
        u64 i = 0;
        for (StrListNode *number = split_data.first->next; number; number = number->next) {
            board_numbers[i] = parse_number(number->s);
            i++;
        }
        assert(i == board_number_count);
    }

    u64 winning_score = 0;
    u64 win_count = 0;
    u64 board_count = board_number_count / 25;
    bool *board_win_status = AM_MEM_ARENA_PUSH_ARRAY(&a, bool, board_count);
    memset(board_win_status, 0, board_count * sizeof(bool));

    for (u64 drawn_i = 0; drawn_i < drawn_number_count; drawn_i++) {
        s64 drawn = drawn_numbers[drawn_i];

        for (u64 board_i = 0; board_i < board_number_count; board_i++) {
            if (board_numbers[board_i] == drawn) {
                board_numbers[board_i] = -1;
            }
        }

        u8 row_count = 0;
        u8 col_count[5] = {0};
        for (u64 board_i = 0; board_i < board_number_count; board_i++) {
            u64 board = board_i / 25;
            if (board_win_status[board]) {
                continue;
            }

            u64 cell = board_i % 25;
            u64 row = cell / 5;
            u64 col = cell % 5;

            row_count      += board_numbers[board_i] == -1;
            col_count[col] += board_numbers[board_i] == -1;

            bool game_won = false;
            if ((cell + 1) / 5 != row) {
                if (row_count == 5) {
                    game_won = true;
                }
                row_count = 0;
            }

            if (row == 4) {
                if (col_count[col] == 5) {
                    game_won = true;
                }
                col_count[col] = 0;
            }

            if (game_won) {
                board_win_status[board] = true;
                win_count++;
                if (win_count == board_count) {
                    for (u64 i = board * 25; i < board * 25 + 25; i++) {
                        winning_score += board_numbers[i] * (board_numbers[i] != -1);
                    }
                    winning_score *= drawn;
                    goto game_over;
                }
                row_count = 0;
                memset(col_count, 0, 5);
            }
        }
    }

game_over:
    if (win_count) {
        printf("Winning score of last winning board: %" PRIu64 "\n", winning_score);
    } else {
        printf("No Winning Board!\n");
    }

    am_mem_arena_release(&a);
    return 0;
}
