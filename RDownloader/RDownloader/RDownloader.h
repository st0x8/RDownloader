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
#import "RDownloadTask.h"
#import "AFNetworkReachabilityManager.h"

/**
 *  @author Roy Lin
 *
 *  How to calculate the progress.
 */
typedef NS_ENUM(char, ProgressType){
    /**
     *  @author Roy Lin
     *
     *  Calculate the progress according to the file size.
     */
    BaseFileSize,
    /**
     *  @author Roy Lin
     *
     *  Calculate the progress according to the task number.
     */
    BaseTaskNumber
};

@protocol RDownloaderDelegate <NSObject>

@required
/**
 *  @author Roy Lin
 *
 *  Add or delete one task will call this callback.
 *
 *  @param tasks How many tasks exist.
 */
- (void)didTaskBatchChange:(NSArray *)tasks;

@optional
- (void)didReachOverallProgress:(float)progress;
- (void)didReachIndividualPrgress:(float)progress task:(RDownloadTask *)task;
- (void)didCompletedOneTask:(RDownloadTask *)task;
- (void)didcompletedAllTask:(NSArray *)tasks;
- (void)didHintErrorOnTask:(RDownloadTask *)task;

@end

@interface RDownloader : NSObject

@property (nonatomic, readonly) float overallProgress;
@property (nonatomic) BOOL overrideSameNameFile;
@property (nonatomic) BOOL networkReachable;
@property (nonatomic) ProgressType progressType;
@property (nonatomic, readonly) int64_t countOfBytesWritten;
@property (nonatomic, readonly) int64_t countOfBytesExceptedToWrite;
/**
 *  @author Roy Lin
 *
 *  Set the destination folder where the downloaded file will stroage.
 */
@property (nonatomic, strong) NSString *absoluteDestinationPath;
@property (nonatomic, copy) NSArray *allTasks;
@property (nonatomic, weak) id <RDownloaderDelegate> delegate;//Note strong reference cycle, iOS5 and up can use weak
@property (nonatomic) AFNetworkReachabilityStatus networkStatu;
+ (instancetype)shareInstance;
- (RDownloadTask *)addRDownloadTask:(RDownloadTask *)task;
- (RDownloadTask *)addTask:(NSDictionary *)taskInfo;
- (NSArray *)addTasks:(NSArray *)taskInfos;
- (RDownloadTask *)startRDownloadTask:(RDownloadTask *)task;
- (RDownloadTask *)downloadTask:(NSDictionary *)taskInfo;
- (NSArray *)downloadTasks:(NSArray *)taskInfos;
- (RDownloadTask *)pauseTask:(RDownloadTask *)task;
- (NSArray *)deleteTask:(RDownloadTask *)task;
- (void)startAllTasks;
- (void)pauseAllTasks;
@end
