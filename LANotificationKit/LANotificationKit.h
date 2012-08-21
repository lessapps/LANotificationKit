//
//  LANotificationCenter.h
//  Healthier
//
//  Created by Artem Vovk & Shuo Yang on 8/14/12.
//  Copyright (c) 2012 LessApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

typedef void (^DidClickBlock) (void);

@interface LANotificationCenter : NSObject<GrowlApplicationBridgeDelegate, NSUserNotificationCenterDelegate>

+ (LANotificationCenter *)sharedInstance;

- (id)init;

- (void)notifyWithTitle:(NSString *)title
            description:(NSString *)description
          didClickBlock:(DidClickBlock)didClickBlockOrNil;

- (void)removeAllNotifications;

@end
