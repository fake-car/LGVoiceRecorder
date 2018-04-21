//
//  AppDelegate.m
//  LGVoiceRecordDemo
//
//  Created by inter on 2018/4/21.
//  Copyright © 2018年 inter. All rights reserved.
//

#import "AppDelegate.h"
#import "PIVoiceRecordViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.backgroundColor = [UIColor whiteColor];
    _window.rootViewController = [[PIVoiceRecordViewController alloc] init];
    [_window makeKeyAndVisible];

    return YES;
}




@end
