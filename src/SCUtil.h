#define SC21_DEBUG 1

#ifdef SC21_DEBUG
#undef SC21_DEBUG
#define SC21_DEBUG(...) NSLog(__VA_ARGS__)
#else
#define SC21_DEBUG(...) ((void) 0)
#endif

// #define SC21_ENV_DEBUG(_SC_env, _SC_str)              \
// if (_SC_env environment variable is set) NSLog(_SC_str)
