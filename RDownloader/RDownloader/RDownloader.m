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
#import "RDownloadTask.h"


@interface RDownloader () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSMutableArray *taskBatch;
@property (nonatomic, strong) NSURLSession *backgroundSession;
@property (nonatomic) NSInteger completedNumber;
@property (nonatomic) NSInteger uncountBytesTaskNumber;//Use to count the task which not yet get how many bytes to write and how many bytes received

@end

@implementation RDownloader

@synthesize overallProgress = _overallProgress;

+ (instancetype)shareInstance {
    static RDownloader *downloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[[self class] alloc] init];
        downloader.overrideSameNameFile = NO;
        downloader.taskBatch = [NSMutableArray array];
        downloader.progressType = BaseFileSize;
        downloader.absoluteDestinationPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.st0x8.RDownloader.NSURLSession"];
        downloader.backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:downloader delegateQueue:nil];
        [downloader getOutstandingTaskFromSession];
        downloader.networkReachable = NO;
        [downloader monitorNetworkStatus];
    });
    return downloader;
}

- (RDownloadTask *)addTask:(NSDictionary *)taskInfo {
    RDownloadTask *task;
    if (taskInfo[@"URL"]) {
        task = [[RDownloadTask alloc] initWithURL:taskInfo[@"URL"] andFileName:taskInfo[@"fileName"] destinationPath:taskInfo[@"destinationPath"]];
        task.taskInterrupt = TaskInterruptCreateTask;
    } else {
        [NSException raise:@"RDownloadTaskInitialization" format:@"The URL can not be nil."];
    }
    return [self addRDownloadTask:task];
}

- (RDownloadTask *)downloadTask:(NSDictionary *)taskInfo {
    RDownloadTask *task;
    if (taskInfo[@"URL"]) {
        task = [[RDownloadTask alloc] initWithURL:taskInfo[@"URL"] andFileName:taskInfo[@"fileName"] destinationPath:taskInfo[@"destinationPath"]];
        task.taskInterrupt = TaskInterruptAutoConnect;
    } else {
        [NSException raise:@"RDownloadTaskInitialization" format:@"The URL can not be nil."];
    }
    return [self startRDownloadTask:task];
}

- (RDownloadTask *)pauseTask:(RDownloadTask *)task {
    if (task.isComplete) {
        return task;
    }
    [task.sessionDownloadTask suspend];
    return task;
}

- (NSArray *)downloadTasks:(NSArray *)taskInfos {
    for (NSDictionary *taskInfo in taskInfos) {
        [self downloadTask:taskInfo];
    }
    return self.taskBatch;
}

- (NSArray *)addTasks:(NSArray *)taskInfos {
    for (NSDictionary *taskInfo in taskInfos) {
        [self addTask:taskInfo];
    }
    return self.taskBatch;
}

- (NSArray *)deleteTask:(RDownloadTask *)task {
    if ([self.taskBatch containsObject:task]) {
        if (!task.isUncountBytes) {
            _countOfBytesExceptedToWrite -= task.totalBytesOfFile;
            _countOfBytesWritten -= task.totalBytesWritten;
        }
        [self.taskBatch removeObject:task];
        if (task.isComplete) {
            _completedNumber --;
        }
        if (task.absoluteDestinationPath) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            if ([fileManager fileExistsAtPath:task.absoluteDestinationPath]) {
                [fileManager removeItemAtPath:task.absoluteDestinationPath error:&error];
            }
            if (error) {
                NSLog(@"Delete task (%@) have error: %@.", task.URL, error);
            }
        }
        task.sessionDownloadTask = nil;
        task = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(didTaskBatchChange:)]) {
            [self.delegate didTaskBatchChange:self.taskBatch];
        }
        
    } else {
        NSLog(@"Task (%@) is not exist!", task.URL);
    }
    return self.taskBatch;
}

- (NSArray *)allTasks {
    return self.taskBatch;
}

- (float)overallProgress {
    static float preProgress;
    if (self.completedNumber == self.taskBatch.count) {
        return 1;
    }
    if (self.progressType == BaseFileSize && self.uncountBytesTaskNumber == 0) {//Return progress base task nubmer when bytes number has not ready
        _overallProgress = (float)_countOfBytesWritten / _countOfBytesExceptedToWrite;
        //The progress base bytes number maybe less than the progress base task number which return already. In the case, return the progress alredy be returned.
        if (_overallProgress < preProgress) {
            _overallProgress = preProgress;
        }
        if (isnan(_overallProgress)) {
            _overallProgress = 0;
        }
    } else {
        _overallProgress = (float)self.completedNumber / self.taskBatch.count;
    }
    preProgress = _overallProgress;
    return _overallProgress;
}

- (RDownloadTask *)startRDownloadTask:(RDownloadTask *)task {
    if (task.isComplete) {
        return task;
    }
    task = [self addRDownloadTask:task];
    if (self.networkReachable) {
        [task.sessionDownloadTask resume];
    } else {
        task.taskInterrupt = TaskInterruptAutoConnect;
    }
    return task;
}

- (RDownloadTask *)addRDownloadTask:(RDownloadTask *)task {
    if ([self.taskBatch containsObject:task]) {
        if (task.sessionDownloadTask) {
            return task;
        } else {
            if (task.taskInterrupt == TaskInterruptNone) {
                NSLog(@"%@ was already downloaded.", task.fileName);
            }
        }
        if (task.taskInterrupt == TaskInterruptError) {
            NSLog(@"%@ have error: %@.", task.fileName, task.errorDescription);
        }
    } else {
        RDownloadTask *existTask;
        for (RDownloadTask *rdTask in self.taskBatch) {
            if ([task.URL isEqual:rdTask.URL]) {
                existTask = rdTask;
                break;
            }
        }
        if (existTask) {//existTask is a uncompleted from getTasksWithCompletionHandler.
            existTask.fileName = task.fileName;
            NSString *filePath;
            if (task.destinationPath) {
                filePath = [NSString stringWithFormat:@"%@/%@/%@", self.absoluteDestinationPath, task.destinationPath, task.fileName];
            } else {
                filePath  = [NSString stringWithFormat:@"%@/%@", self.absoluteDestinationPath, task.fileName];
            }
            existTask.absoluteDestinationPath = filePath;
            task = existTask;
        } else {
            task = [self createNewTask:task];
        }
    }
    return task;
}

- (void)startAllTasks {
    for (RDownloadTask *rdTask in self.taskBatch) {
        [rdTask.sessionDownloadTask resume];
        if (rdTask.taskInterrupt == TaskInterruptCreateTask) {
            rdTask.taskInterrupt = TaskInterruptAutoConnect;
        }
        [self updateIndividualProgressAndOveralProgressInMainThread:rdTask];
    }
}

- (void)pauseAllTasks {
    for (RDownloadTask *rdTask in self.taskBatch) {
        if (rdTask.sessionTaskState == NSURLSessionTaskStateRunning) {//Send suspend twice will make task can not resume
            [rdTask.sessionDownloadTask suspend];
        }
        if (rdTask.taskInterrupt == TaskInterruptAutoConnect) {
            rdTask.taskInterrupt = TaskInterruptCreateTask;
        }
        [self updateIndividualProgressAndOveralProgressInMainThread:rdTask];
    }
}

//Get the uncompleted tasks.
- (void)getOutstandingTaskFromSession {
    [self.backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            if (downloadTask.state == NSURLSessionTaskStateRunning) {
                [downloadTask suspend];
            }
            RDownloadTask *task = [[RDownloadTask alloc] initWithNSURLSessionDownloadTask:downloadTask];
            if (task.totalBytesOfFile == 0) {
                task.totalBytesOfFile = downloadTask.countOfBytesExpectedToReceive;
                task.fileSize = [self calculateFileSize:task.totalBytesOfFile];
                _countOfBytesExceptedToWrite += task.totalBytesOfFile;
                task.isUncountBytes = NO;
            }
            if (task.totalBytesOfFile == 0) {//Use to calculate progress
                task.isUncountBytes = YES;
                self.uncountBytesTaskNumber++;
            }
            _countOfBytesWritten = _countOfBytesWritten - task.totalBytesWritten + downloadTask.countOfBytesReceived;
            task.totalBytesWritten = downloadTask.countOfBytesReceived;
            [self.taskBatch addObject:task];
            if (self.delegate && [self.delegate respondsToSelector:@selector(didTaskBatchChange:)]) {
                [self.delegate didTaskBatchChange:self.taskBatch];
            }
        }
    }];
}

- (RDownloadTask *)createNewTask:(RDownloadTask *)task {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath;
    NSError *error;
    if (task.destinationPath) {
        filePath = [NSString stringWithFormat:@"%@/%@/%@", self.absoluteDestinationPath, task.destinationPath, task.fileName];
    } else {
        filePath  = [NSString stringWithFormat:@"%@/%@", self.absoluteDestinationPath, task.fileName];
    }
    task.absoluteDestinationPath = filePath;
    if ([fileManager fileExistsAtPath:filePath]) {
        if (!self.overrideSameNameFile) {
            self.completedNumber++;
            NSLog(@"File (%@) already exist!", task.fileName);
            NSDictionary *fileInfo = [fileManager attributesOfItemAtPath:filePath error:&error];
            task.totalBytesOfFile = [[fileInfo objectForKey:NSFileSize] longLongValue];
            task.totalBytesWritten = task.totalBytesOfFile;
            _countOfBytesWritten += task.totalBytesWritten;
            _countOfBytesExceptedToWrite += task.totalBytesOfFile;
            task.fileSize = [self calculateFileSize:task.totalBytesOfFile];
            task.progress = 1;
            task.error = error;
            task.isComplete = YES;
            task.isUncountBytes = NO;
            task.taskInterrupt = TaskInterruptNone;
            if (self.delegate && [self.delegate respondsToSelector:@selector(didCompletedOneTask:)]) {//Call this delegate method dividually to ensure this method will be called once.
                [self.delegate didCompletedOneTask:task];
            }
        } else {
            [fileManager removeItemAtPath:filePath error:&error];
            NSLog(@"Delete samename file (%@)!", task.fileName);
        }
    } else {
        [fileManager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        task.error = error;
    }
    
    if (!task.isComplete) {//The NSURLSessionDownloadTask will be created still when offline.
        //NSURLRequest *requet = [[NSURLRequest alloc] initWithURL:task.URL];
        // task.sessionDownloadTask = [self.backgroundSession downloadTaskWithRequest:requet];
        task.isUncountBytes = YES;
        if (self.networkReachable) {
            [self DetectHostAndGetFilesize:task];
        }
    }
    [self.taskBatch addObject:task];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTaskBatchChange:)]) {
        [self.delegate didTaskBatchChange:self.taskBatch];
    }
    [self updateIndividualProgressAndOveralProgressInMainThread:task];
    return task;
}

- (void)DetectHostAndGetFilesize:(RDownloadTask *)task {
    NSMutableURLRequest *requet = [[NSMutableURLRequest alloc] initWithURL:task.URL];
    requet.timeoutInterval = 160;
    [requet setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    requet.HTTPMethod = @"HEAD";
    //Background session won't try to initiate the connections util the remote server is reachable.We should check reachability before initiating the request.
    NSURLSessionDataTask *headTask = [[NSURLSession sharedSession] dataTaskWithRequest:requet completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (error) {
                task.error = error;
                [self updateIndividualProgressAndOveralProgressInMainThread:task];
            } else {
                self.uncountBytesTaskNumber++;
                NSURLRequest *request = [[NSURLRequest alloc] initWithURL:task.URL];
                task.sessionDownloadTask = [self.backgroundSession downloadTaskWithRequest:request];
                if (task.taskInterrupt == TaskInterruptAutoConnect) {
                    [task.sessionDownloadTask resume];
                }
                task.taskInterrupt = TaskInterruptNone;
            }
        });
    }];
    [headTask resume];
}

- (RDownloadTask *)findRDownloadTaskFromTaskBatch:(NSURLSessionTask *)downloadTask {
    for (RDownloadTask *task in self.taskBatch) {
        if (task.sessionDownloadTask == downloadTask) {
            return task;
        }
    }
    return nil;
}

- (void)updateIndividualProgressAndOveralProgressInMainThread:(RDownloadTask *)task {
    if (task.error && !task.isComplete) {
        if (!task.isComplete) {
            task.isComplete = YES;
            _completedNumber++;
            if (self.delegate && [self.delegate respondsToSelector:@selector(didCompletedOneTask:)]) {//Call this delegate method dividually to ensure this method will be called once.
                [self.delegate didCompletedOneTask:task];
            }
        }
        task.taskInterrupt = TaskInterruptError;
    }
    if (self.delegate) {
        if (task.error) {
            if ([self.delegate respondsToSelector:@selector(didHintErrorOnTask:)]) {
                [self.delegate didHintErrorOnTask:task];
            }
        }
        if ([self.delegate respondsToSelector:@selector(didReachIndividualPrgress:task:)]) {
            [self.delegate didReachIndividualPrgress:task.progress task:task];
        }
        if ([self.delegate respondsToSelector:@selector(didReachOverallProgress:)]) {
            [self.delegate didReachOverallProgress:self.overallProgress];
        }
        if (_completedNumber == self.taskBatch.count) {
            if ([self.delegate respondsToSelector:@selector(didcompletedAllTask:)]) {
                [self.delegate didcompletedAllTask:self.taskBatch];
            }
            
        }
    }
}

- (void)updateIndividualProgressAndOveralProgress:(RDownloadTask *)task {
    if (task.error && !task.isComplete) {
        task.isComplete = YES;
        _completedNumber++;
        if (self.delegate && [self.delegate respondsToSelector:@selector(didCompletedOneTask:)]) {//Call this delegate method dividually to ensure this method will be called once.
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate didCompletedOneTask:task];
            });
        }
        task.taskInterrupt = TaskInterruptError;
    }
    if (self.delegate) {
        if (task.error) {
            if ([self.delegate respondsToSelector:@selector(didHintErrorOnTask:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate didHintErrorOnTask:task];
                });
            }
        }
        if ([self.delegate respondsToSelector:@selector(didReachIndividualPrgress:task:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate didReachIndividualPrgress:task.progress task:task];
            });
        }
        if ([self.delegate respondsToSelector:@selector(didReachOverallProgress:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate didReachOverallProgress:self.overallProgress];
            });
        }
        if (_completedNumber == self.taskBatch.count) {
            if ([self.delegate respondsToSelector:@selector(didcompletedAllTask:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate didcompletedAllTask:self.taskBatch];
                });
            }
        }
    }
}

- (void)TasksOnline {
    for (int i = 0; i < self.taskBatch.count; i++) {
        RDownloadTask *task = self.taskBatch[i];
        if (task.taskInterrupt == TaskInterruptAutoConnect || task.taskInterrupt == TaskInterruptCreateTask) {
            if (task.sessionDownloadTask) {
                [task.sessionDownloadTask resume];
                task.taskInterrupt = TaskInterruptNone;
            } else {
                [self DetectHostAndGetFilesize:task];
            }
            
        }
    }
}

- (void)TasksOffline {
    for (int i = 0; i < self.taskBatch.count; i++) {
        RDownloadTask *task = self.taskBatch[i];
        if (task.sessionDownloadTask && task.sessionDownloadTask.state == NSURLSessionTaskStateRunning) {
            [task.sessionDownloadTask suspend];
            task.taskInterrupt = TaskInterruptAutoConnect;
        }
    }
}

- (NSString *)calculateFileSize:(int64_t)fileInBytes {
    //NSString *fileSize = @"";
    if (fileInBytes >= pow(1024, 3)) {
        return [NSString stringWithFormat:@"%.2fGB",((float)fileInBytes / pow(1024, 3))];
    } if (fileInBytes >= pow(1024, 2)) {
        return  [NSString stringWithFormat:@"%.2fMB",((float)fileInBytes / pow(1024, 2))];
    } if (fileInBytes >= 1024) {
        return  [NSString stringWithFormat:@"%.2fKB", ((float)fileInBytes / 1024)];
    } else {
        return [NSString stringWithFormat:@"%lluBytes", fileInBytes];
    }
}

- (uint64_t)getFreeDiskSpace {
    uint64_t totalSpace = 0;
    uint64_t totalFreSpace = 0;
    NSError *error;
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSDictionary *infoDir = [[NSFileManager defaultManager] attributesOfFileSystemForPath:path error:&error];
    if (infoDir) {
        NSNumber *fileSystemSizeInBytes = [infoDir objectForKey:NSFileSystemSize];
        NSNumber *fileSystemFreeSizeInBytes = [infoDir objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreSpace = [fileSystemFreeSizeInBytes unsignedLongLongValue];
        NSLog(@"Disk total space of %llu MiB with %llu MiB free space available.", ((totalSpace/1024ll)/1024ll), ((totalFreSpace/1024ll)/1024ll));
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return totalFreSpace;
}

- (void)monitorNetworkStatus {
    __weak __typeof(self) weakSelf = self;
    AFNetworkReachabilityManager *moniter = [AFNetworkReachabilityManager sharedManager];
    [moniter startMonitoring];
    [moniter setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus statu) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        switch (statu) {
            case AFNetworkReachabilityStatusNotReachable:
                strongSelf.networkStatu = AFNetworkReachabilityStatusNotReachable;
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                strongSelf.networkStatu = AFNetworkReachabilityStatusReachableViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                strongSelf.networkStatu = AFNetworkReachabilityStatusReachableViaWiFi;
                break;
                
            case AFNetworkReachabilityStatusUnknown:
                strongSelf.networkStatu = AFNetworkReachabilityStatusUnknown;
                break;
        }
        self.networkReachable = (statu != AFNetworkReachabilityStatusNotReachable);
        if (strongSelf.networkReachable) {
            [strongSelf TasksOnline];
        } else {
            [strongSelf TasksOffline];
        }
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    RDownloadTask *task = [self findRDownloadTaskFromTaskBatch:downloadTask];
    if (task) {
        if (task.totalBytesOfFile == 0) {
            task.totalBytesOfFile = totalBytesExpectedToWrite;
            task.fileSize = [self calculateFileSize:totalBytesExpectedToWrite];
            _countOfBytesExceptedToWrite += task.totalBytesOfFile;
        }
        if (task.isUncountBytes) {
            self.uncountBytesTaskNumber--;
            task.isUncountBytes = NO;
        }
        _countOfBytesWritten = _countOfBytesWritten - task.totalBytesWritten + totalBytesWritten;
        task.totalBytesWritten = totalBytesWritten;
        [self updateIndividualProgressAndOveralProgress:task];
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    RDownloadTask *rdTask = [self findRDownloadTaskFromTaskBatch:task];
    if (rdTask && error) {
        self.uncountBytesTaskNumber--;//The task hit error, so can not count his bytes
        rdTask.error = error;
        [self updateIndividualProgressAndOveralProgress:rdTask];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    RDownloadTask *task = [self findRDownloadTaskFromTaskBatch:downloadTask];
    if (task) {
        self.completedNumber++;
        task.isComplete = YES;
        task.sessionDownloadTask = nil;
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filePath;
        if (task.destinationPath) {
            filePath = [NSString stringWithFormat:@"%@/%@/%@", self.absoluteDestinationPath, task.destinationPath, task.fileName];
        } else {
            filePath  = [NSString stringWithFormat:@"%@/%@", self.absoluteDestinationPath, task.fileName];
        }
        if ([fileManager fileExistsAtPath:filePath]) {
            [fileManager removeItemAtPath:filePath error:nil];
        }
        [fileManager moveItemAtPath:location.path toPath:filePath error:&error];
        task.error = error;
        task.progress = 1;
        NSLog(@"original path: %@ path: %@ error: %@", location.path, filePath, error.localizedDescription);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didCompletedOneTask:)]) {//Call this delegate method dividually to ensure this  method will be called once.
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate didCompletedOneTask:task];
            });
        }
        
        [self updateIndividualProgressAndOveralProgress:task];
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

@end
