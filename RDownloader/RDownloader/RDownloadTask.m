//
//  RDownloadeTask.m
//  RDownloader
//
//  Created by lin on 15/9/8.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//
//  https://github.com/st0x8/RDownloader
//

#import "RDownloadTask.h"
#import "RDownloader.h"

@implementation RDownloadTask

- (instancetype)initWithURL:(id<NSCopying,NSObject>)URL andFileName:(NSString *)fileName destinationPath:(NSString *)path {
    if (self = [super init]) {
        if ([URL isKindOfClass:[NSURL class]]) {
            self.URL = (NSURL *)URL;
        } else if ([URL isKindOfClass:[NSString class]]){
            self.URL = [NSURL URLWithString:[(NSString *)URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];//support Chinese
        } else {
            [NSException raise:@"RDownloadTaskInitialization" format:@"The URL must be NSString instance or NSURL instance."];
        }
        if (fileName && fileName.length > 0) {
            self.fileName = fileName;
        } else {
            self.fileName = [self.URL lastPathComponent];
        }
        self.destinationPath = path;//If the path is nil. it will be determine when the task download complete.
        self.taskInterrupt = TaskInterruptNone;
        self.isComplete = NO;
        self.isUncountBytes = YES;
        self.totalBytesWritten = 0;
        self.totalBytesOfFile = 0;
        self.fileSize = @"unknown";
    }
    return self;
}

- (instancetype)initWithNSURLSessionDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    if (self = [super init]) {
        self.sessionDownloadTask = downloadTask;
        self.URL = downloadTask.originalRequest.URL;
        self.fileName = [self.URL lastPathComponent];
        self.taskInterrupt = TaskInterruptNone;
        self.isComplete = NO;
        self.isUncountBytes = YES;
        self.fileSize = @"unknown";
    }
    return self;
}

- (float)progress {
    if (self.isComplete) {
        return 1;
    }
    if (self.totalBytesWritten == 0 || self.totalBytesOfFile == 0) {
        return 0;
    }
    return (float)self.totalBytesWritten / self.totalBytesOfFile;
}

- (NSString *)errorDescription {
    if (self.error) {
        return [NSString stringWithFormat:@"Downloading URL %@ failed. Error: %@", self.URL, self.error];
    }
    return @"No error";
}

- (NSURLSessionTaskState)sessionTaskState {
    return self.sessionDownloadTask.state;
}

- (void)start {
    [[RDownloader shareInstance] startRDownloadTask:self];
}

- (void)pause {
    [[RDownloader shareInstance] pauseTask:self];
}

- (void)deleteTask {
    [[RDownloader shareInstance] deleteTask:self];
}

@end
