#ifndef AM_LIST_H
#define AM_LIST_H

#define DLL_APPEND_NP(f, l, n, next, prev)  \
    ((f) == NULL                            \
        ? ((f) = (l) = (n)                  \
            , (f)->prev = (n)->next = NULL) \
        : ((n)->prev = (l)                  \
            , (l)->next = (n)               \
            , (l) = (n)                     \
            , (n)->next = NULL))

#define DLL_REMOVE_NP(f, l, n, next, prev)     \
    ((f) == (l) && (f) == (n)                  \
        ? ((f) = (l) = NULL)                   \
        : ((f) == (n)                          \
            ? ((f) = (f)->next                 \
                , (f)->prev = NULL)            \
            : ((l) == (n)                      \
                ? ((l) = (l)->prev             \
                    , (l)->next = NULL)        \
                : ((n)->prev->next = (n)->next \
                    , (n)->next->prev = (n)->prev))))

#define SLL_QUEUE_PUSH_N(f, l, n, next) \
    ((f) == NULL                        \
        ? ((f) = (l) = (n))             \
        : ((l)->next = (n)              \
            , (l) = (n)                 \
            , (n)->next = NULL))

#define SLL_QUEUE_PUSH_FRONT_N(f, l, n, next) \
    ((f) == NULL                              \
        ? ((f) = (l) = (n)                    \
            , (n)->next = NULL)               \
        : ((n)->next = (f)                    \
            , (f) = (n)))

// TODO: It's maybe somewhat surprising to the user that these pop functions
// don't return the popped node.
#define SLL_QUEUE_POP_N(f, l, next) \
    ((f) == (l)                     \
        ? ((f) = (l) = NULL)        \
        : ((f) = (f)->next))


#define SLL_STACK_PUSH_N(f, n, next) ((n)->next = (f), (f) = (n))

#define SLL_STACK_POP_N(f, next) \
    ((f) == NULL                 \
        ? 0                      \
        : ((f) = (f)->next))

#define DLL_APPEND(f, l, n)  DLL_APPEND_NP((f), (l), (n), next, prev)
#define DLL_PREPEND(f, l, n) DLL_APPEND_NP((l), (f), (n), prev, next)
#define DLL_REMOVE(f, l, n)  DLL_REMOVE_NP((f), (l), (n), next, prev)

#define SLL_QUEUE_PUSH(f, l, n)       SLL_QUEUE_PUSH_N((f), (l), (n), next)
#define SLL_QUEUE_PUSH_FRONT(f, l, n) SLL_QUEUE_PUSH_FRONT_N((f), (l), (n), next)
#define SLL_QUEUE_POP(f, l)           SLL_QUEUE_POP_N((f), (l), next)

#define SLL_STACK_PUSH(f, n) SLL_STACK_PUSH_N((f), (n), next)
#define SLL_STACK_POP(f)     SLL_STACK_POP_N((f), next)

#if defined(AM_INCLUDE_TESTS)
typedef struct TestNode TestNode;
struct TestNode {
    TestNode *next;
    TestNode *prev;
    s32 val;
};

internal void am_list_test(void) {
    TestNode nodes[10] = {0};
    for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
        nodes[i].val = i;
    }

    {
        TestNode *first = NULL;
        TestNode *last = NULL;

        printf("dll append and remove from front\n");
        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            DLL_APPEND(first, last, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf(" <|> ");
            for (TestNode *n = last; n; n = n->prev) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            DLL_REMOVE(first, last, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf(" <|> ");
            for (TestNode *n = last; n; n = n->prev) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        printf("dll prepend and remove from back\n");
        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            DLL_PREPEND(first, last, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf(" <|> ");
            for (TestNode *n = last; n; n = n->prev) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            DLL_REMOVE(first, last, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf(" <|> ");
            for (TestNode *n = last; n; n = n->prev) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        printf("dll append and remove from middle\n");
        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            DLL_APPEND(first, last, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf(" <|> ");
            for (TestNode *n = last; n; n = n->prev) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            DLL_REMOVE(first, last, &nodes[(i + (ARRAY_COUNT(nodes) / 2)) % ARRAY_COUNT(nodes)]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf(" <|> ");
            for (TestNode *n = last; n; n = n->prev) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }
    }

    {
        TestNode *first = NULL;
        TestNode *last = NULL;

        printf("sll queue push and pop\n");
        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            SLL_QUEUE_PUSH(first, last, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        while (first) {
            SLL_QUEUE_POP(first, last);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        printf("sll queue push front and pop\n");
        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            SLL_QUEUE_PUSH_FRONT(first, last, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        while (first) {
            SLL_QUEUE_POP(first, last);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }
    }

    {
        TestNode *first = NULL;

        printf("sll stack push and pop\n");
        for (size_t i = 0; i < ARRAY_COUNT(nodes); i++) {
            SLL_STACK_PUSH(first, &nodes[i]);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }

        while (first) {
            SLL_STACK_POP(first);
            printf("[");
            for (TestNode *n = first; n; n = n->next) {
                printf(" %i ", n->val);
            }
            printf("]\n");
        }
    }
}
#endif // defined(AM_INCLUDE_TESTS)

#endif // AM_LIST_H
