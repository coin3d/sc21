//FIXME: [self class] always return the actual Class of the self object.
//       We want the class currently in scope. How?
#ifdef SC21_DEBUG
#define SC21_LOG_METHOD NSLog(@"%@.%@", [self class], NSStringFromSelector(_cmd))
#else
#define SC21_LOG_METHOD ((void) 0)
#endif

#ifdef SC21_DEBUG
#undef SC21_DEBUG
#define SC21_DEBUG(...) NSLog(__VA_ARGS__)
#else
#define SC21_DEBUG(...) ((void) 0)
#endif

// #define SC21_ENV_DEBUG(_SC_env, _SC_str)              \
// if (_SC_env environment variable is set) NSLog(_SC_str)

