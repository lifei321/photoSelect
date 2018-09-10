//
//  ViewController.m
//  photo
//
//  Created by lifei14 on 2018/9/10.
//  Copyright © 2018年 lifei14. All rights reserved.
//


/*       NSPhotoLibraryUsageDescription   App需要您的同意,才能访问相册     */

#import "ViewController.h"
#import "LGPhoto.h"
#import "LGPhotoPickerCommon.h"

@interface ViewController ()<LGPhotoPickerViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 300, 300)];
    button.backgroundColor = [UIColor orangeColor];
    [button addTarget:self action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonClicked {
    [self presentPhotoPickerViewControllerWithStyle:LGShowImageTypeImagePicker];
}

/**
 *  初始化相册选择器
 */
- (void)presentPhotoPickerViewControllerWithStyle:(LGShowImageType)style {
    LGPhotoPickerViewController *pickerVc = [[LGPhotoPickerViewController alloc] initWithShowType:style];
    pickerVc.status = PickerViewShowStatusCameraRoll;
    pickerVc.maxCount = 9;   // 最多能选9张图片
    pickerVc.delegate = self;
    //    pickerVc.nightMode = YES;//夜间模式
    [pickerVc showPickerVc:self];
}

#pragma mark - LGPhotoPickerViewControllerDelegate

- (void)pickerViewControllerDoneAsstes:(NSArray <LGPhotoAssets *> *)assets isOriginal:(BOOL)original {
    
     //assets的元素是LGPhotoAssets对象，获取image方法如下:
     NSMutableArray *thumbImageArray = [NSMutableArray array];
     NSMutableArray *originImage = [NSMutableArray array];
     NSMutableArray *fullResolutionImage = [NSMutableArray array];
     
     for (LGPhotoAssets *photo in assets) {
         //缩略图
         [thumbImageArray addObject:photo.thumbImage];
         //原图
         [originImage addObject:photo.originImage];
     }
    
    NSInteger num = (long)assets.count;
    NSString *isOriginal = original? @"YES":@"NO";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"发送图片" message:[NSString stringWithFormat:@"您选择了%ld张图片\n是否原图：%@",(long)num,isOriginal] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}


@end
