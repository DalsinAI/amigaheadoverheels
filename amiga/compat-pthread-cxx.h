/* AmigaOS libpthread defines read(...) and sleep(...) as function-like
 * macros when unistd.h was previously included. These macros corrupt
 * std::istream::read and other C++ standard library declarations.
 * Preload both headers, then suppress only the cancellation wrappers.
 */
#ifdef __cplusplus
#include <unistd.h>
#include <pthread.h>
#ifdef read
#undef read
#endif
#ifdef sleep
#undef sleep
#endif
#ifdef close
#undef close
#endif
#ifdef fsync
#undef fsync
#endif
#ifdef usleep
#undef usleep
#endif
#endif
