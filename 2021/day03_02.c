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

u64 filter_by_bit_frequency(u64 *numbers, u64 num_numbers, u64 number_width, bool most_popular) {
    u64 first = 0;
    u64 opl = num_numbers;

    u64 digit = 0;
    while (opl - first > 1) {
        assert(digit < number_width);

        //printf("Candidates for digit %" PRIu64 "\n", digit);
        //for (u64 i = first; i < opl; i++) {
        //    char buf[64] = {0};
        //    for (size_t digit_i = 0; digit_i < number_width; digit_i++) {
        //        buf[digit_i] = ((numbers[i] >> (number_width - 1 - digit_i)) & 1) + '0';
        //    }
        //    printf("%4" PRIu64 ": %-4" PRIu64 " %s\n", i, numbers[i], buf);
        //}

        for (u64 i = first; i < opl; i++) {
            if (((numbers[i] >> (number_width - 1 - digit)) & 1)) {
                if ((i - first) > ((opl - first) / 2)) {
                    // Zero is more frequent
                    most_popular ? (opl = i) : (first = i);
                } else {
                    // One is more or equally frequent
                    most_popular ? (first = i) : (opl = i);
                }
                assert(first < opl);
                break;
            }
        }

        digit++;
    }
    assert(opl - first == 1);
    return numbers[first];
}

int main(void) {
    MemArena a = am_mem_arena_create(am_mem_base_allocator_malloc());
    Str input = open_file(&a, "day03_input.txt");
    StrList lines = am_str_split(&a, input, (u8 *)"\n", 1);

    u64 num_numbers = lines.node_count;
    u64 *numbers = AM_MEM_ARENA_PUSH_ARRAY(&a, u64, num_numbers);
    assert(numbers);
    memset(numbers, 0, num_numbers);

    u64 width = lines.first->s.size;
    {
        u64 numbers_i = 0;
        for (StrListNode *line = lines.first; line; line = line->next) {
            assert(line->s.size == width);
            for (u64 i = 0; i < width; i++) {
                numbers[numbers_i] |= (line->s.str[i] == '1') << (width - i - 1);
            }
            numbers_i++;
        }
    }

    qsort(numbers, num_numbers, sizeof(u64), &compare_u64);

    u64 o2_generator_rating = filter_by_bit_frequency(numbers, num_numbers, width, true);
    u64 co2_scrubber_rating = filter_by_bit_frequency(numbers, num_numbers, width, false);

    //printf("Oxygen Generator Rating: %" PRIu64 "\n", o2_generator_rating);
    //printf("CO2 Scrubber Rating:     %" PRIu64 "\n", co2_scrubber_rating);
    printf("Life Support Rating: %" PRIu64 "\n", o2_generator_rating * co2_scrubber_rating);

    am_mem_arena_release(&a);
    return 0;
}
