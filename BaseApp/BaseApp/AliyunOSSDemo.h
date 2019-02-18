//
//  oss_ios_demo.h
//  oss_ios_demo
//
//  Created by liufuhao on 2019/2/18.
//  Copyright © 2019年 LFH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OSSPhotoObj.h"

typedef NS_ENUM(NSInteger, UploadImageState) {
    UploadImageSuccess,          
    UploadImageFail
};

typedef NS_ENUM(NSInteger, DownImageState) {
    DownImageSuccess,
    DownImageFail
};

@interface AliyunOSSDemo : NSObject

+ (instancetype)sharedInstance;

- (void)setupEnvironment;

- (void)runDemo;

- (void)uploadObjectAsync;

- (void)downloadObjectAsync;

- (void)resumableUpload;

- (void)uploadIdentityPic_uuid:(NSString *)uuid uploadingData:(NSData *)uploadingData;



////    在上传文件是，如果把ObjectKey写为"folder/subfolder/file"，即是模拟了把文件上传到folder/subfolder/下的file文件。注意，路径默认是”根目录”，不需要以’/‘开头

+ (void)uploadImageDic:(NSDictionary *)imageDic
               isAsync:(BOOL)isAsync
              complete:(void(^)(UploadImageState state))complete;

+ (void)downLoadImagesName:(NSArray <NSString *>*)imageNames
                   isAsync:(BOOL)isAsync
                  complete:(void(^)(NSDictionary *imageDic, DownImageState state))complete;

+ (void)uploadPhotos:(NSMutableArray <OSSPhotoObj *>*)photos
            complete:(void(^)(UploadImageState state))complete;

@end
