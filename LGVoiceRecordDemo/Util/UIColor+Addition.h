//
//  UIColor+Addition.h
//  AfterSchool
//
//  Created by Chenxi Cai on 14-11-20.
//  Copyright (c) 2014年 AfterSchool. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface UIColor (Addition)

+ (UIColor *)colorWithHex:(NSString *)hexColor;
+ (UIColor *)colorWithHex:(NSString *)hexColor alpha:(float)hexAlpha;
+ (UIColor *)viewBackColor;

@end
