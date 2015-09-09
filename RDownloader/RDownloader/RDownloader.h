//
//  RDownloader.h
//  RDownloader
//
//  Created by lin on 15/9/8.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//
//  https://github.com/st0x8/RDownloader
//

#import <Foundation/Foundation.h>

@class RDownloadTask;
@protocol RDownloaderUIDelegate <NSObject>

@required

@optional

@end

@protocol RDownloaderDataDelegate <NSObject>

@required

@optional

@end

@interface RDownloader : NSObject

+ (instancetype)shareDownloader;
- (void)startDownload;
- (BOOL)isDownloading;
- (void)startDownloadTask:(RDownloadTask *)task;
- (void)startDownloadTasks:(NSArray *)tasks;

@property (nonatomic, strong) id <RDownloaderUIDelegate> delegate;
@property (nonatomic) NSInteger totalTaskNumber;
@property (nonatomic) NSInteger completedTaskNumber;
@property (nonatomic, strong) NSArray *allTasks;

@end
