#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FzhBluetooth.h"
#import "FzhCallBlock.h"
#import "FzhString.h"

FOUNDATION_EXPORT double FZBluetoothVersionNumber;
FOUNDATION_EXPORT const unsigned char FZBluetoothVersionString[];

