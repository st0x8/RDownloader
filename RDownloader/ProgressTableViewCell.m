//
//  ProgressTableViewCell.m
//  RDownloader
//
//  Created by lin on 15/9/11.
//  Copyright (c) 2015年 Roy Lin. All rights reserved.
//

#import "ProgressTableViewCell.h"

@implementation ProgressTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateProgress:(float)progress {
    self.progress.progress = progress;
}

- (IBAction)operateButtonTap:(UIButton *)sender {
    if (self.operateButtonTap) {
        self.operateButtonTap(sender);
    };
}

@end
