// Debug levels: 0-off, 1-error, 2-warn, 3-method, 4-info, 5-verbose
#define DEBUG_LEVEL 4

#define DEBUG_ERROR    (DEBUG_LEVEL >= 1)
#define DEBUG_WARN     (DEBUG_LEVEL >= 2)
#define DEBUG_METHOD   (DEBUG_LEVEL >= 3)
#define DEBUG_INFO     (DEBUG_LEVEL >= 4)
#define DEBUG_VERBOSE  (DEBUG_LEVEL >= 5)

#define DBLogError(format, ...)     if(DEBUG_ERROR)   NSLog((format), ##__VA_ARGS__)
#define DBLogWarn(format, ...)      if(DEBUG_WARN)    NSLog((format), ##__VA_ARGS__)
#define DBLogMethod(format, ...)    if(DEBUG_METHOD)  NSLog(format, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#define DBLogInfo(format, ...)      if(DEBUG_INFO)    NSLog((format), ##__VA_ARGS__)
#define DBLogVerbose(format, ...)   if(DEBUG_VERBOSE) NSLog((format), ##__VA_ARGS__)

// DLOG takes a format argument (which must begin %s) and 0 or more args:
// DLOG(@"%s");
// DLOG(@"%s: %d", x);
//#define DLOG(fmt, ...) NSLog(fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)

#define NSLogHereIAm() NSLog(@"got selector %@ at line %d, file %s", \
NSStringFromSelector(_cmd), __LINE__, __FILE__)
