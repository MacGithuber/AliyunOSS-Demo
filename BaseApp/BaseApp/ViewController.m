//
//  ViewController.m
//  BaseApp
//
//  Created by liufuhao on 2019/2/18.
//  Copyright © 2019年 LFH. All rights reserved.
//

#import "ViewController.h"
#import "AliyunOSSDemo.h"
#import "OSSPhotoObj.h"
#import "SVProgressHUD.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self uploadAliyunOSS];
}

- (void)uploadAliyunOSS{
    NSString *upload_Environment = @"prod";
    NSString *userName = @"12345678901";
    UIImage *uploadImg = [UIImage new];
    NSMutableArray *images = [NSMutableArray arrayWithObject:uploadImg];
    
    NSMutableArray *photoObjs = [NSMutableArray array];
    for (NSInteger i = 0; i < images.count; i++) {
        OSSPhotoObj *obj = [OSSPhotoObj new];
        obj.photo = images[i];
        obj.objectKey = [NSString stringWithFormat:@"%@/%@/image/%@.jpg",upload_Environment,userName,[NSUUID UUID].UUIDString];
        [photoObjs addObject:obj];
        NSLog(@"objectKey %@",obj.objectKey);
    }
    
    NSLog(@"上传开始------------");
    [AliyunOSSDemo uploadPhotos:photoObjs complete:^(UploadImageState state) {
        if (state == UploadImageSuccess) {
            NSMutableArray *imgUrls = [NSMutableArray array];
            for (OSSPhotoObj *obj in photoObjs) {
                [imgUrls addObject:obj.objectKey];
            }
            [SVProgressHUD showErrorWithStatus:@"上传成功"];

        }else{
            [SVProgressHUD showErrorWithStatus:@"上传失败"];
        }
    }];
}

@end
