#ifndef AM_MEMORY_H
#define AM_MEMORY_H

#define MEM_KIB(b) ((u64)(b) << 10)
#define MEM_MIB(b) ((u64)(b) << 20)
#define MEM_GIB(b) ((u64)(b) << 30)

#define AM_MEM_RESERVE_FN(name) void *(name)(void *ctx, u64 size)
typedef AM_MEM_RESERVE_FN(am_mem_reserve_fn);

#define AM_MEM_CHANGE_FN(name) void (name)(void *ctx, void *ptr, u64 size)
typedef AM_MEM_CHANGE_FN(am_mem_change_fn);

typedef struct {
    am_mem_reserve_fn* reserve;
    am_mem_change_fn* commit;
    am_mem_change_fn* decommit;
    am_mem_change_fn* release;
    void *ctx;
} BaseAllocator;

#define AM_MEM_ARENA_COMMIT_BLOCK_SIZE MEM_MIB(64)
#define AM_MEM_ARENA_DEFAULT_RESERVE_SIZE MEM_GIB(1)

typedef struct {
    BaseAllocator *base;
    u8 *mem;
    u64 cap;
    u64 pos;
    u64 commit_pos;
} MemArena;

internal AM_MEM_CHANGE_FN(am_mem_change_noop) {
    UNUSED(ctx);
    UNUSED(ptr);
    UNUSED(size);
}

internal AM_MEM_RESERVE_FN(am_mem_reserve_malloc) {
    UNUSED(ctx);
    return malloc(size);
}

internal AM_MEM_CHANGE_FN(am_mem_release_malloc) {
    UNUSED(ctx);
    UNUSED(size);
    free(ptr);
}

internal BaseAllocator *am_mem_base_allocator_malloc(void) {
    local_persist BaseAllocator b;
    if (!b.reserve) {
        b = (BaseAllocator) {
            .reserve = am_mem_reserve_malloc,
            .commit = am_mem_change_noop,
            .decommit = am_mem_change_noop,
            .release = am_mem_release_malloc,
        };
    }
    return &b;
}

internal MemArena am_mem_arena_create_reserve(BaseAllocator *base, u64 reserve_size) {
    MemArena a = {
        .base = base,
    };
    a.mem = a.base->reserve(a.base->ctx, reserve_size);
    a.cap = reserve_size;
    return a;
}

internal MemArena am_mem_arena_create(BaseAllocator *base) {
    return am_mem_arena_create_reserve(base, AM_MEM_ARENA_DEFAULT_RESERVE_SIZE);
}

internal void *am_mem_arena_push(MemArena *a, u64 size) {
    void *result = NULL;
    if (a->mem + size <= a->mem + a->cap) {
        result = a->mem + a->pos;
        a->pos += size;

        if (a->pos > a->commit_pos) {
            u64 aligned = ALIGN_UP_POW_2(a->pos, AM_MEM_ARENA_COMMIT_BLOCK_SIZE);
            u64 next_commit_pos = CLAMP_TOP(aligned, a->cap);
            u64 commit_size = next_commit_pos - a->commit_pos;
            a->base->commit(a->base->ctx, a->mem + a->commit_pos, commit_size);
            a->commit_pos = next_commit_pos;
        }
    }
    return result;
}

#define AM_MEM_ARENA_PUSH_ARRAY(arena, T, count) (am_mem_arena_push((arena), sizeof(T) * (count)))

internal void am_mem_arena_pop_to(MemArena *a, u64 pos) {
    if (pos < a->pos) {
        a->pos = pos;

        u64 aligned = ALIGN_UP_POW_2(a->pos, AM_MEM_ARENA_COMMIT_BLOCK_SIZE);
        u64 next_commit_pos = CLAMP_TOP(aligned, a->cap);
        if (next_commit_pos < a->commit_pos) {
            u64 decommit_size = a->commit_pos - next_commit_pos;
            a->base->decommit(a->base->ctx, a->mem + a->commit_pos, decommit_size);
            a->commit_pos = next_commit_pos;
        }
    }
}

internal void am_mem_arena_release(MemArena *a) {
    a->base->release(a->base->ctx, a->mem, a->cap);
    *a = (MemArena){0};
}

// TODO: SIMD
internal void am_mem_copy(void *dst, void *src, u64 size) {
    for (u64 i = 0; i < size; i++) {
        ((u8 *)dst)[i] = ((u8 *)src)[i];
    }
}

internal bool am_mem_equal(void *dst, void *src, u64 size) {
    for (u64 i = 0; i < size; i++) {
        if (((u8 *)dst)[i] != ((u8 *)src)[i]) {
            return false;
        }
    }
    return true;
}

#if defined(AM_INCLUDE_TESTS)
internal void am_memory_test(void) {
    assert(MEM_KIB(10) == 10240);
    assert(MEM_MIB(10) == 10485760);
    assert(MEM_GIB(10) == 10737418240);

    {
        BaseAllocator *a = am_mem_base_allocator_malloc();
        u64 num_test_ints = 10;
        s32 *int_buf = a->reserve(NULL, num_test_ints * sizeof(s32));
        assert(int_buf);
        a->release(NULL, int_buf, 0);
    }

    {
        MemArena a = am_mem_arena_create(am_mem_base_allocator_malloc());
        am_mem_arena_push(&a, 1020);
        assert(a.pos == 1020);
        u64 p = a.pos;
        u64 cp = a.commit_pos;

        AM_MEM_ARENA_PUSH_ARRAY(&a, u8, a.cap - a.pos);
        assert(a.pos == a.cap);
        assert(a.commit_pos == a.cap);

        am_mem_arena_pop_to(&a, p);
        assert(a.pos == p);
        assert(a.commit_pos == cp);

        am_mem_arena_release(&a);
        assert(a.pos == 0);
        assert(a.commit_pos == 0);
        assert(a.mem == NULL);
    }

    {
        u8 src[10] = {0};
        u8 dst[10] = {0};
        for (u64 i = 0; i < ARRAY_COUNT(src); i++) {
            src[i] = i;
        }

        am_mem_copy(dst, src, ARRAY_COUNT(dst));
        assert(am_mem_equal(dst, src, ARRAY_COUNT(dst)));
    }
}
#endif // defined(AM_INCLUDE_TESTS)

#endif // AM_MEMORY_H
