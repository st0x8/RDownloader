//
//  AppDelegate.h
//  RDownloader
//
//  Created by lin on 15/8/19.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//
//  https://github.com/st0x8/RDownloader
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, copy) void(^backgroundTransferCompletionHandler)();

@end

