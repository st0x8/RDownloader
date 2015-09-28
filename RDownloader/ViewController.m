//
//  ViewController.m
//  RDownloader
//
//  Created by lin on 15/8/19.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//
//  https://github.com/st0x8/RDownloader
//
#import "ViewController.h"
#import "ProgressTableViewCell.h"
#import "RDownloader.h"
#import "RDownloadTask.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, RDownloaderDelegate>

@property (strong, nonatomic) IBOutlet UIProgressView *overallProgress;
@property (strong, nonatomic) IBOutlet UILabel *overallProgressLabel;
@property (strong, nonatomic) IBOutlet UITableView *tasksTable;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *taskButton;
@property (nonatomic, strong) RDownloader *downloader;
@property (nonatomic, strong) NSArray *allTaskArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.downloader = [RDownloader shareInstance];
    self.downloader.delegate = self;
//    self.downloader.overrideSameNameFile = YES;
//    self.downloader.progressType = BaseTaskNumber;
    
    self.allTaskArray = self.downloader.allTasks;
    self.tasksTable.dataSource = self;
    self.tasksTable.delegate = self;
    
    //Use the keyword "URL" "fileName" "destinationPath" to create a new task. If you do not set file name, the file name will create by url.
    [self.downloader addTask:@{@"URL":@"http://z19.9553.com/game19/雨天.rar", @"destinationPath":@"test"}];
    [self.downloader addTask:@{@"URL":@"http://b.zol-img.com.cn/desk/bizhi/image/1/2880x1800/1347960622548.jpg" ,@"fileName":@"pool.jpg"}];
    [self.downloader addTask:@{@"URL":@"http://z9553.com/game19/errortest.zip"}];//The URL is invalid.
    [self.downloader addTasks:@[@{@"URL":@"http://b.zol-img.com.cn/desk/bizhi/image/1/2880x1800/134796056845.jpg", @"fileName":@"autumn.jpg", @"destinationPath":@"test"},  @{@"URL":@"http://b.zol-img.com.cn/desk/bizhi/image/1/2880x1800/1347961131580.jpg"}, @{@"URL":@"http://z9553.com/game19/errortest.zip"}]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)buttonTap:(UIBarButtonItem *)sender {
    if ([sender.title isEqualToString:@"Complete"]) {
        return;
    }
    if ([sender.title isEqualToString:@"Start"]) {
        sender.title = @"Pause";
        [self.downloader startAllTasks];
    } else {
        sender.title = @"Start";
        [self.downloader pauseAllTasks];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allTaskArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 135;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cellIdentifier";
    ProgressTableViewCell *cell = (ProgressTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

    RDownloadTask *task = self.allTaskArray[indexPath.row];
    cell.fileNameLabel.text = task.fileName;
    cell.sizeLabel.text = task.fileSize;
    cell.progress.progress = task.progress;
    if (task.errorDescription) {
        cell.stateLabel.text = task.errorDescription;
    }
    if (task.isComplete) {
        [cell.operateButton setTitle:@"Complete" forState:UIControlStateNormal];
    } else if (task.sessionDownloadTask) {
        if (task.sessionTaskState == NSURLSessionTaskStateRunning) {
            [cell.operateButton setTitle:@"Suspend" forState:UIControlStateNormal];
        } else if (task.sessionTaskState == NSURLSessionTaskStateSuspended) {
            [cell.operateButton setTitle:@"Start" forState:UIControlStateNormal];
        }
    }
    cell.progressNumberLabel.text = [NSString stringWithFormat:@"%.2f%%",task.progress * 100];
    __weak __typeof(task) weakTask = task;
    cell.operateButtonTap = ^(UIButton *button) {
        if (![button.titleLabel.text isEqualToString:@"Complete"]) {
            if (weakTask.sessionTaskState == NSURLSessionTaskStateRunning) {
                [weakTask.sessionDownloadTask suspend];
                [button setTitle:@"Start" forState:UIControlStateNormal];
            } else if (weakTask.sessionTaskState == NSURLSessionTaskStateSuspended) {
                [weakTask.sessionDownloadTask resume];
                [button setTitle:@"Suspend" forState:UIControlStateNormal];
            }
        }
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RDownloadTask *task = self.allTaskArray[indexPath.row];
        [task deleteTask];
    }
}

- (void)didTaskBatchChange:(NSArray *)tasks {
    [self.tasksTable reloadData];
}

- (void)didReachIndividualPrgress:(float)progress task:(RDownloadTask *)task {
    NSIndexPath *index = [NSIndexPath indexPathForItem:[self.allTaskArray indexOfObject:task] inSection:0];
    [self.tasksTable reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)didCompletedOneTask:(RDownloadTask *)task {
    NSLog(@"%@ download complete!", task.fileName);
}

- (void)didReachOverallProgress:(float)progress {
    self.overallProgress.progress = progress;
    self.overallProgressLabel.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
}

- (void)didcompletedAllTask:(NSArray *)tasks {
    self.taskButton.title = @"Complete";
    NSLog(@"All tasks complete!");
}

- (void)didHintErrorOnTask:(RDownloadTask *)task {
    NSLog(@"%@ have error: %@.", task.fileName, task.errorDescription);
}

@end
