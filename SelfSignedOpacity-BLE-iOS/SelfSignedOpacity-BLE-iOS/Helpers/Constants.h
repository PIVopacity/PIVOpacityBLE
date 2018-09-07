#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


#define def_key(name) extern NSString* const name
#define def_int(name, value) extern int const name
#define def_type(type, name, value) extern type const name


typedef enum{
    kAppOpacityBLE = 5001
} appIDs;


// padding for margins
#define kLeftMargin				20.0
#define kTopMargin				20.0
#define kRightMargin			20.0
#define kBottomMargin			20.0
#define kTweenMargin			10.0

// control dimensions
#define kStdButtonWidth			106.0
#define kStdButtonHeight		40.0
#define kSegmentedControlHeight 40.0
#define kPageControlHeight		20.0
#define kPageControlWidth		160.0
#define kSliderHeight			7.0
#define kSwitchButtonWidth		94.0
#define kSwitchButtonHeight		27.0
#define kTextFieldHeight		30.0
#define kSearchBarHeight		40.0
#define kLabelHeight			20.0
#define kProgressIndicatorSize	40.0
#define kCameraToolbarHeight	55.0
#define kUIProgressBarWidth		160.0
#define kUIProgressBarHeight	24.0

#define kNavBarHeight			44.0
#define kNavBarHeightPortrait	44.0
#define kNavBarHeightLandscape	32.0

#define kTabBarHeight			44.0
#define kTabBarHeightPortrait	44.0
#define kTabBarHeightLandscape	32.0

#define kToolBarHeight			44.0
#define kToolBarHeightPortrait	44.0
#define kToolBarHeightLandscape	32.0

// specific font metrics used in our text fields and text views
#define kFontName				@"Arial"
#define kTextFieldFontSize		18.0
#define kTextViewFontSize		18.0

// UITableView row heights
#define kUIRowHeight			50.0
#define kUIRowLabelHeight		22.0

// table view cell content offsets
#define kCellLeftOffset			8.0
#define kCellTopOffset			12.0

#define kViewfinderHeight   240.0
#define kViewfinderWidth    240.0

#define kDefaultAllowedScans 1000000;

#define kCreditCardHeight 276.0
#define kCreditCardMargin 25.0
#define kCreditCardOverlap 60.0

// table colors
//#define kOddBackgroundColor [UIColor appleLiteGray];
#define kOddBackgroundColor [UIColor whiteColor];
#define kEvenBackgroundColor [UIColor appleMidBlue];

#define degreesToRadian(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI)

typedef enum  {
	kWhiteColor,
	kBlackColor,
	kRedColor,
	kGreenColor,
	kBlueColor
} buttonColor;

typedef enum {
	kCMD,
	kPOLL
} dataType;

typedef enum {
	kSwitchAlignmentLeft,
	kSwitchAlignmentRight,
	kSwitchAlignmentNone
} switchAlignment;

typedef enum {
    kNoTrack,
	kRedTrack,
	kYellowTrack,
	kGreenTrack,
	kBlueTrack,
    kWhiteTrack,
    kBlackTrack
} trackColors;

//Touches, Gestures, Taps, Swips and Pinches
#define kMinimumGestureLength 25
#define kMaximumVariance 15
#define kMinimumPinchDelta 80
#define ktouchFreezeTime 0.4
#define ktouchDelayTime 0.25 //ktouchFreezeTime must be > ktouchDurationTime

typedef enum {
	kTouchNone,
	kTouchSingle,
	kTouchMulti
} TouchType;

typedef enum {
	kGestureNone,
	kGestureTap,
	kGestureSwipe,
	kGesturePinch
} GestureType;

typedef enum{
	kSwipeNoDirection,
	kSwipeLeft,
	kSwipeRight,
	kSwipeUp,
	kSwipeDown
} SwipeDirection;

typedef enum{
	kPinchNoDirection,
	kPinchIn,
	kPinchOut
} PinchDirection;

typedef enum{
	kRotateNoDirection,
	kRotateClockwise,
	kRotateCounterClockwise
} RotateDirection;

typedef enum Periods {
    kPeriods7Days = 7,
    kPeriods14Days = 14,
    kPeriods30Days = 30,
    kPeriods60Days = 60,
    kPeriods90Days = 90
} Periods;

typedef enum OpacityBLEAppTypes {
    kOpacityBLEAppTypeNone,
    kOpacityBLEAppTypeCentral,
    kOpacityBLEAppTypePeripheral
} OpacityBLEAppTypes;

typedef enum {
    kStatusUnknown,
    kStatusSignedIn,
    kStatusSignedOut,
    kStatusAuthenticated
} StatusType;



