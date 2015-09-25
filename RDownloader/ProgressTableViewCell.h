//
//  ProgressTableViewCell.h
//  RDownloader
//
//  Created by lin on 15/9/11.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *sizeLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progress;
@property (strong, nonatomic) IBOutlet UILabel *progressNumberLabel;
@property (strong, nonatomic) IBOutlet UILabel *stateLabel;
@property (strong, nonatomic) IBOutlet UIButton *operateButton;
@property (nonatomic, copy) void (^operateButtonTap)(UIButton *button);

- (void)updateProgress:(float)progress;

@end
