//
//  LAAppDelegate.m
//  LANotificationKitDemo
//
//  Created by Artem Vovk on 8/17/12.
//  Copyright (c) 2012 LessApps. All rights reserved.
//

#import "LAAppDelegate.h"
#import <LANotificationKit/LANotificationKit.h>

@implementation LAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{


}
- (IBAction)notifyButtonDidTap:(id)sender
{
    [[LANotificationCenter sharedInstance] notifyWithTitle:@"Title" description:@"Desc" didClickBlock:^{
        NSLog(@"Callback");
    }];
}

@end
