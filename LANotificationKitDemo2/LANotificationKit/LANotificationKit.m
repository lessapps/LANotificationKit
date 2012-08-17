//
//  LANotificationCenter.m
//  Healthier
//
//  Created by Artem Vovk & Shuo Yang on 8/14/12.
//  Copyright (c) 2012 LessApps. All rights reserved.
//

#import "LANotificationKit.h"

static NSString *KEY_BLOCK_ID = @"id";


@interface LANotificationCenter ()
@property (nonatomic) BOOL hasNotificationCenter;
@property (strong, nonatomic) NSMutableDictionary *didClickBlocks;
@end


@implementation LANotificationCenter

+ (LANotificationCenter *)sharedInstance
{
    static LANotificationCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LANotificationCenter alloc] init];
    });
    return sharedInstance;
}


- (id)init
{
    self = [super init];
    if (self) {
        self.didClickBlocks = [[NSMutableDictionary alloc] init];
        self.hasNotificationCenter = (BOOL)[NSUserNotificationCenter class];
        //        sharedInstance.hasNotificationCenter = NO;
        
        if (self.hasNotificationCenter) {
            [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        } else {
            [self initGrowlFramework];
        }
    }
    return self;
}


- (void)initGrowlFramework
{
    // Growl stuff
    
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *path = [[mainBundle privateFrameworksPath] stringByAppendingPathComponent:@"LANotificationKit.framework/Frameworks/Growl"];
	if(NSAppKitVersionNumber >= NSAppKitVersionNumber10_6)
		path = [path stringByAppendingPathComponent:@"1.3"];
	else
		path = [path stringByAppendingPathComponent:@"1.2.3"];
	
	path = [path stringByAppendingPathComponent:@"Growl.framework"];
	NSLog(@"path: %@", path);
	NSBundle *growlFramework = [NSBundle bundleWithPath:path];
	if([growlFramework load])
	{
		NSDictionary *infoDictionary = [growlFramework infoDictionary];
		NSLog(@"Using Growl.framework %@ (%@)",
			  [infoDictionary objectForKey:@"CFBundleShortVersionString"],
			  [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]);
        
		Class GAB = NSClassFromString(@"GrowlApplicationBridge");
		if([GAB respondsToSelector:@selector(setGrowlDelegate:)])
			[GAB performSelector:@selector(setGrowlDelegate:) withObject:self];
	}
}

-(NSDictionary *)registrationDictionaryForGrowl{
    NSArray *notifications;
    notifications = [NSArray arrayWithObjects: [[[NSBundle mainBundle] infoDictionary]   objectForKey:@"CFBundleName"], nil];
    
    NSDictionary *dict;
    
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
            notifications, GROWL_NOTIFICATIONS_ALL,
            notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
    
    return (dict);
}

- (void)notifyWithTitle:(NSString *)title
            description:(NSString *)description
          didClickBlock:(DidClickBlock)didClickBlockOrNil
{
    NSString *uuid = [self nextUUID];
    if (didClickBlockOrNil) {
        [self.didClickBlocks setObject:[didClickBlockOrNil copy] forKey:uuid];
    }
    NSDictionary *info = @{ KEY_BLOCK_ID: uuid };
    
    if (self.hasNotificationCenter)
    {
        [self notifyUsingNotificationCenterWithInfo:info title:title description:description];
    }
    else
    {
        [self notifyUsingGrowlWithInfo:info title:title description:description];
    }
}


- (void)notifyUsingGrowlWithInfo:(NSDictionary *)info
                           title:(NSString *)title
                     description:(NSString *)description
{
    Class GAB = NSClassFromString(@"GrowlApplicationBridge");
    if([GAB respondsToSelector:@selector(notifyWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:)])
        [GAB notifyWithTitle:title
                 description:description
            notificationName:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]
                    iconData:nil
                    priority:0
                    isSticky:NO
                clickContext:info];
}


- (void)notifyUsingNotificationCenterWithInfo:(NSDictionary *)info
                                        title:(NSString *)title
                                  description:(NSString *)description
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = description;
    notification.userInfo = info;
    //    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}


- (NSString *)nextUUID
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    return uuidString;
}


- (void)handleNotificationDidClickWithInfo:(NSDictionary *)info
{
    NSString *uuid = info[KEY_BLOCK_ID];
    DidClickBlock block = self.didClickBlocks[uuid];
    if (block) {
        block();
        [self.didClickBlocks removeObjectForKey:uuid];
    }
}


- (void)removeAllNotifications
{
    // Only relevant for Notification Center
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    [self.didClickBlocks removeAllObjects];
}



#pragma mark -
#pragma mark GrowlApplicationBridgeDelegate

- (void)growlNotificationTimedOut:(NSDictionary *)clickContext
{
    NSString *uuid = clickContext[KEY_BLOCK_ID];
    [self.didClickBlocks removeObjectForKey:uuid];
}


- (void)growlNotificationWasClicked:(NSDictionary *)clickContext
{
    [self handleNotificationDidClickWithInfo:clickContext];
}


#pragma mark -
#pragma mark NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    // For DEBUGGING only.
    // Show notification also when the app window is key window
    return YES;
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    [self handleNotificationDidClickWithInfo:notification.userInfo];
    [center removeDeliveredNotification:notification];
}



@end
