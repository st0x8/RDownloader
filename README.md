# RDownloader
RDownloader is a multiple files asynchronous download manager for iOS based on NSURLSession. RDownloader is a singleton instance and can thus be called in your code safely.
##Features
1. Pause and resume a download
2. Download files in background
3. Download large files
4. Download multiple files at a time
5. Resume downloads if app was quit
6. Keeping track of progress

##Requirements
1. Add SystemConfiguration.framework
2. RDownloader requires iOS 7.x or greater

##Installation
1. Copy all files in "RDownloader" folder from sample project to your project.
2. Import SystemConfiguration.framework

##Usage
<p align="center">
<img style='border:1px solid #ccc;' src="https://github.com/st0x8/RDownloader/raw/master/screenshot.jpg" alt="Running Example" title="Running Example">
</p>
RDownloader provides facilties for the following task:

1. Keeping track of one downloaded file progres via delegate method
2. Keeping track of overall progres via delegate method
3. Being notified of the download completion of one file via delegate method
4. Being notified of the download completion of all files via delegate method
5. Checking for file existence (Override to download again or not)
6. Change progress mode (Base file size or task number)

All the following instance methods can be called directly on ```[RDownloader shareInstance]```.
####If override the already existy file
```self.downloader.overrideSameNameFile = YES;```
Every task will check the destination path weather the file exist before download. If override, the task will download, either, the task will be completed.
####Set progress mode
```self.downloader.progressType = BaseTaskNumber;```
####Download one file
```[[RDownloader shareInstance] addTask:@{@"URL":@"http://z19.9553.com/game19/雨天.rar", @"destinationPath":@"test"}];```

####Download files
```[[RDownloader shareInstance] addTasks:@[@{@"URL":@"http://b.zol-img.com.cn/desk/bizhi/image/1/2880x1800/134796056845.jpg", @"fileName":@"autumn.jpg", @"destinationPath":@"test"},  @{@"URL":@"http://b.zol-img.com.cn/desk/bizhi/image/1/2880x1800/1347961131580.jpg"}, @{@"URL":@"http://z9553.com/game19/errortest.zip"}]];```

## License

Usage is provided under the [MIT License](http://opensource.org/licenses/mit-license.php).  See LICENSE for the full details.
