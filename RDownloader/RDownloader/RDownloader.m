//
//  RDownloader.m
//  RDownloader
//
//  Created by lin on 15/9/8.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//
//  https://github.com/st0x8/RDownloader
//

#import "RDownloader.h"

@interface RDownloader () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSMutableArray *taskBatch;
@property (nonatomic) int64_t allTasksBytes;
@property (nonatomic, strong) NSURLSession *backgroundSession;

@end

@implementation RDownloader

+ (instancetype)shareDownloader {
    static dispatch_once_t onceToken;
    static RDownloader *downloader;
    dispatch_once(&onceToken, ^ {
        downloader = [[[self class] alloc] init];
        downloader.taskBatch = [NSMutableArray array];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.st0x8.RDownloader.NSURLSession"];
        downloader.backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:downloader delegateQueue:nil];
    });
    return downloader;
}

- (NSArray *)allTasks {
    return [self.taskBatch copy];
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
}

@end
