#import "Constants.h"

#undef def_key 
#define def_key(name) NSString *const name = @#name

#undef def_int
#define def_int(name, value) int const name = value

#undef def_type
#define def_type(type, name, value) type const name = value
