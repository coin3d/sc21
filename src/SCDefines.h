#ifdef __cplusplus
#define SC21_EXTERN		extern "C"
#else
#define SC21_EXTERN		extern
#endif

SC21_EXTERN const double SC21VersionNumber;

// Version numbers are increased by the following scheme:
// o Micro versions (e.g. 1.0.1): changes only after the decimal point
// o Minor versions (e.g. 1.1.0): increase by some number (might be >1 if
//                                there were intermediate beta releases)
// o Major versions:              basically the same as for minor versions
//                                but the Letter version will also change
//                                (e.g. A -> B).
#define SC21VersionNumber1_0 3
//FIXME: or: #define SC21_VERSION_1_0 3
