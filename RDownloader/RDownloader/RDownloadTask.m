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

@implementation RDownloadTask

- (instancetype)initWithURL:(id <NSCopying, NSObject>)URL andFileName:(NSString *)fileName andDestinationPath:(NSString *)destinationPath {
    if (self = [super init]) {
        if ([URL isKindOfClass:[NSURL class]]) {
            self.DownloadURL = (NSURL *)URL;
        } else if ([URL isKindOfClass:[NSString class]]) {
            self.DownloadURL = [[NSURL alloc] initWithString:(NSString *)URL];
        } else {
            [NSException raise:@"RDownloadTaskInitialization" format:@"The URL must be NSString instance or NSURL instance."];
        }
        self.isCompleted = NO;
        self.totalBytesWritten = 0;
        self.totalBytesExpectedToWrite = 0;
        if (fileName) {
            self.fileName = fileName;
        } else {
            self.fileName = [self.DownloadURL lastPathComponent];
        }
        
    }
    return self;
}

- (void)destoryTask {
    
}

- (NSString *)errorDescription {
    if (self.error) {
        NSInteger errorCode = [self.error code];
        return [NSString stringWithFormat:@"Downloading URL %@ failed because of error: %@ (Code %lu)", [self.DownloadURL path], [self.error localizedDescription], errorCode];
    }
    return @"No error";
}

- (NSString *)absoluteDestinationPath {
    if (self.absoluteDestinationPath) {
        return _absoluteDestinationPath;
    }
    NSString *path = NSSearchPathForDirectoriesInDomains(NSUserDirectory, NSUserDomainMask, YES)[0];
    return [NSString stringWithFormat:@"%@%@", path, @"/Library/"];
}
@end
