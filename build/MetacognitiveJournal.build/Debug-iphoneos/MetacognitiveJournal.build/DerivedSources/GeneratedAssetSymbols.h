#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.geekedoutinnovations.MetacognitiveJournal";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "Color" asset catalog color resource.
static NSString * const ACColorNameColor AC_SWIFT_PRIVATE = @"Color";

/// The "Image" asset catalog image resource.
static NSString * const ACImageNameImage AC_SWIFT_PRIVATE = @"Image";

#undef AC_SWIFT_PRIVATE
