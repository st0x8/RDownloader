//
//  RDownloadeTask.h
//  RDownloader
//
//  Created by lin on 15/9/8.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//
//  https://github.com/st0x8/RDownloader
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(char, TaskStatus) {
    TaskStatuCompleted,
    TaskStatuOutstanding,
    TaskStatuError
};

@interface RDownloadTask : NSObject

@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSURL *DownloadURL;
@property (strong, nonatomic) NSString *absoluteDestinationPath;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSString *errorDescription;
@property (nonatomic) BOOL isCompleted;

@property (nonatomic) float downloadingProgress;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) int64_t totalBytesExpectedToWrite;

- (instancetype)initWithURL:(id <NSCopying, NSObject>)URL andFileName:(NSString *)fileName andDestinationPath:(NSString *)destinationPath;
- (void)destoryTask;

@end
