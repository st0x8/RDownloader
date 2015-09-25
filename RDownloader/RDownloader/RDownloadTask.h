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

/**
 *  @author Roy Lin
 *
 *  The task be interrupted by which status.
 */
typedef NS_ENUM(char, TaskInterrupt){
    /**
     *  @author Roy Lin
     *
     *  Is not be interrupted
     */
    TaskInterruptNone,
    /**
     *  @author Roy Lin
     *
     *  Be interrupted by erro
     */
    TaskInterruptError,
    /**
     *  @author Roy Lin
     *
     *  Be interrupted by offline, the task will auto resume when online.
     */
    TaskInterruptAutoConnect,
};

@interface RDownloadTask : NSObject

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *fileSize;
/**
 *  @author Roy Lin
 *
 *  The relative path where the file to stroage. Note the path will be nil when this app is terminated.
 */
@property (nonatomic, strong) NSString *destinationPath;
/**
 *  @author Roy Lin
 *
 *  The absolute path where the file to stroage. Don not manually set this path. The path will create by RDownloader.Note the path will be nil when this app is terminated.
 */
@property (nonatomic, strong) NSString *absoluteDestinationPath;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) int64_t totalBytesOfFile;
@property (nonatomic) float progress;
@property (nonatomic) BOOL isComplete;
/**
 *  @author Roy Lin
 *
 *  Determine weahter the task get file size already. Use to calculate the progress. If unknown the file size, can not calculate the progress base file size.
 */
@property (nonatomic) BOOL isUncountBytes;
@property (nonatomic) TaskInterrupt taskInterrupt;
@property (nonatomic, strong) NSString *errorDescription;
@property (nonatomic, strong) NSError *error;
@property (nonatomic) NSURLSessionTaskState sessionTaskState;
@property (nonatomic, strong) NSURLSessionDownloadTask *sessionDownloadTask;

- (instancetype)initWithURL:(id <NSCopying, NSObject>)URL andFileName:(NSString *)fileName destinationPath:(NSString *)path;
- (instancetype)initWithNSURLSessionDownloadTask:(NSURLSessionDownloadTask *)downloadTask;
- (void)start;
- (void)pause;
- (void)deleteTask;
@end