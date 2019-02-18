//
//  oss_ios_demo.m
//  oss_ios_demo
//
//  Created by liufuhao on 2019/2/18.
//  Copyright © 2019年 LFH. All rights reserved.
//

#import "AliyunOSSDemo.h"
#import <AliyunOSSiOS/OSSService.h>

NSString * const multipartUploadKey = @"multipartUploadObject";


OSSClient * client;
static dispatch_queue_t queue4demo;

@implementation AliyunOSSDemo

+ (instancetype)sharedInstance {
    static AliyunOSSDemo *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [AliyunOSSDemo new];
    });
    return instance;
}

- (void)setupEnvironment {
   // 打开调试log
//   [OSSLog enableLog];

   // 在本地生成一些文件用来演示
//   [self initLocalFile];

   // 初始化sdk
   [self initOSSClient];
}

- (void)runDemo {
    /*************** 以下每个方法调用代表一个功能的演示，取消注释即可运行 ***************/

    // 罗列Bucket中的Object
    // [self listObjectsInBucket];

    // 异步上传文件
    // [self uploadObjectAsync];

    // 同步上传文件
    // [self uploadObjectSync];

    // 异步下载文件
    // [self downloadObjectAsync];

    // 同步下载文件
    // [self downloadObjectSync];

    // 复制文件
    // [self copyObjectAsync];

    // 签名Obejct的URL以授权第三方访问
    // [self signAccessObjectURL];

    // 分块上传的完整流程
    // [self multipartUpload];

    // 只获取Object的Meta信息
    // [self headObject];

    // 罗列已经上传的分块
    // [self listParts];

    // 自行管理UploadId的分块上传
    // [self resumableUpload];
}

// get local file dir which is readwrite able
- (NSString *)getDocumentDirectory {
    NSString * path = NSHomeDirectory();
    NSLog(@"NSHomeDirectory:%@",path);
    NSString * userName = NSUserName();
    NSString * rootPath = NSHomeDirectoryForUser(userName);
    NSLog(@"NSHomeDirectoryForUser:%@",rootPath);
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

// create some random file for demo cases
- (void)initLocalFile {
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * mainDir = [self getDocumentDirectory];

    NSArray * fileNameArray = @[@"file1k", @"file10k", @"file100k", @"file1m", @"file10m", @"fileDirA/", @"fileDirB/"];
    NSArray * fileSizeArray = @[@1024, @10240, @102400, @1024000, @10240000, @1024, @1024];

    NSMutableData * basePart = [NSMutableData dataWithCapacity:1024];
    for (int i = 0; i < 1024/4; i++) {
        u_int32_t randomBit = arc4random();
        [basePart appendBytes:(void*)&randomBit length:4];
    }

    for (int i = 0; i < [fileNameArray count]; i++) {
        NSString * name = [fileNameArray objectAtIndex:i];
        long size = [[fileSizeArray objectAtIndex:i] longValue];
        NSString * newFilePath = [mainDir stringByAppendingPathComponent:name];
        if ([fm fileExistsAtPath:newFilePath]) {
            [fm removeItemAtPath:newFilePath error:nil];
        }
        [fm createFileAtPath:newFilePath contents:nil attributes:nil];
        NSFileHandle * f = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
        for (int k = 0; k < size/1024; k++) {
            [f writeData:basePart];
        }
        [f closeFile];
    }
    NSLog(@"main bundle: %@", mainDir);
}

#pragma mark -
- (void)initOSSClient {
    
    // 自实现签名，可以用本地签名也可以远程加签
    id<OSSCredentialProvider> credential = [[OSSCustomSignerCredentialProvider alloc] initWithImplementedSigner:^NSString *(NSString *contentToSign, NSError *__autoreleasing *error) {
        NSString *signature = [OSSUtil calBase64Sha1WithData:contentToSign withSecret:@"accessKeySecret"];
        if (signature != nil) {
            *error = nil;
        } else {
            // construct error object
            *error = [NSError errorWithDomain:@"OSSClientSignFailed" code:OSSClientErrorCodeSignFailed userInfo:nil];
            return nil;
        }
        return [NSString stringWithFormat:@"OSS %@:%@", @"accessKeyId", signature];
    }];
    
    OSSClientConfiguration * conf = [OSSClientConfiguration new];
    conf.maxRetryCount = 2;
    conf.timeoutIntervalForRequest = 20;
    conf.timeoutIntervalForResource = 24 * 60 * 60;
    
    client = [[OSSClient alloc] initWithEndpoint:@"oss_endPoint" credentialProvider:credential clientConfiguration:conf];

}

#pragma mark work with normal interface

- (void)createBucket {
    OSSCreateBucketRequest * create = [OSSCreateBucketRequest new];
    create.bucketName = @"<bucketName>";
    create.xOssACL = @"public-read";
    create.location = @"oss-cn-hangzhou";

    OSSTask * createTask = [client createBucket:create];

    [createTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"create bucket success!");
        } else {
            NSLog(@"create bucket failed, error: %@", task.error);
        }
        return nil;
    }];
}

- (void)deleteBucket {
    OSSDeleteBucketRequest * delete = [OSSDeleteBucketRequest new];
    delete.bucketName = @"<bucketName>";

    OSSTask * deleteTask = [client deleteBucket:delete];

    [deleteTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"delete bucket success!");
        } else {
            NSLog(@"delete bucket failed, error: %@", task.error);
        }
        return nil;
    }];
}

- (void)listObjectsInBucket {
    OSSGetBucketRequest * getBucket = [OSSGetBucketRequest new];
    getBucket.bucketName = @"android-test";
    getBucket.delimiter = @"";
    getBucket.prefix = @"";


    OSSTask * getBucketTask = [client getBucket:getBucket];

    [getBucketTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            OSSGetBucketResult * result = task.result;
            NSLog(@"get bucket success!");
            for (NSDictionary * objectInfo in result.contents) {
                NSLog(@"list object: %@", objectInfo);
            }
        } else {
            NSLog(@"get bucket failed, error: %@", task.error);
        }
        return nil;
    }];
}

// 开发环境:dev/13242034701/image/uuid.png
// 生产环境:prod/13242034701/image/uuid.png

- (void)uploadIdentityPic_uuid:(NSString *)uuid uploadingData:(NSData *)uploadingData{
    OSSPutObjectRequest * put = [OSSPutObjectRequest new];
    
    // 必填字段
    put.bucketName = @"oss_bucket";
    
    //    在上传文件是，如果把ObjectKey写为"folder/subfolder/file"，即是模拟了把文件上传到folder/subfolder/下的file文件。注意，路径默认是”根目录”，不需要以’/‘开头
    NSString *upload_Environment = @"prod";
    NSString *userName = @"12345678901";
    NSString *objectKey = [NSString stringWithFormat:@"%@/%@/image/%@.jpg",upload_Environment,userName,uuid];
    
    put.objectKey = objectKey;
    put.uploadingData = uploadingData; // 直接上传NSData
    
    // 可选字段，可不设置
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    
    OSSTask * putTask = [client putObject:put];
    [putTask continueWithBlock:^id(OSSTask *task) {
        NSLog(@"objectKey: %@", put.objectKey);
        if (!task.error) {
            NSLog(@"upload object success!");
        } else {
            NSLog(@"upload object failed, error: %@" , task.error);
        }
        return nil;
    }];
}

+ (void)downLoadImagesName:(NSArray <NSString *>*)imageNames
                   isAsync:(BOOL)isAsync
                  complete:(void(^)(NSDictionary *imageDic, DownImageState state))complete{
    
    [[AliyunOSSDemo sharedInstance] setupEnvironment];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = imageNames.count;
    
    NSMutableDictionary *callBackImageDic = [NSMutableDictionary dictionary];
    int i = 0;
    for (NSString *name in imageNames) {
        if (name) {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                
                OSSGetObjectRequest * request = [OSSGetObjectRequest new];
                request.objectKey = name;
                request.bucketName = @"oss_bucket";

                request.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
                    NSLog(@"%lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
                };
                
                OSSTask * getTask = [client getObject:request];
                [getTask waitUntilFinished]; // 阻塞直到下载完成
                
                if (!getTask.error) {
                    NSLog(@"download object success!");
                    OSSGetObjectResult * getResult = getTask.result;
                    NSLog(@"download dota length: %lu", [getResult.downloadedData length]);
                    UIImage *image = [UIImage imageWithData: getResult.downloadedData];
                    if (image) {
                        [callBackImageDic setObject:image forKey:request.objectKey];
                    }
                    
                } else {
                    NSLog(@"download object failed, error: %@" ,getTask.error);
                }
                
                if (isAsync) {
                    if (name == imageNames.lastObject) {
                        NSLog(@"lastObject down object finished!");
                        if (complete) {
                            complete(callBackImageDic ,DownImageSuccess);
                        }
                    }
                }
                
            }];
            if (queue.operations.count != 0) {
                [operation addDependency:queue.operations.lastObject];
            }
            [queue addOperation:operation];
        }
        i++;
    }
    if (!isAsync) {
        [queue waitUntilAllOperationsAreFinished];
        if (complete) {
            if (complete) {
                complete(callBackImageDic, DownImageSuccess);
            }
        }
    }
}

+ (UIImage *)zipScaleWithImage:(UIImage *)sourceImage{
    
    //进行图像尺寸的压缩
    CGSize imageSize = sourceImage.size;//取出要压缩的image尺寸
    CGFloat width = imageSize.width;    //图片宽度
    CGFloat height = imageSize.height;  //图片高度
    
    NSData *data = UIImageJPEGRepresentation(sourceImage, 1.0);
    NSLog(@"图像尺寸压缩前 %.2f M width %.2f height %.2f",data.length/1024.f/1024.f,width,height);

    
    //1.宽高大于1280(宽高比不按照2来算，按照1来算)
    if (width>1280||height>1280) {
        if (width>height) {
            CGFloat scale = height/width;
            width = 1280;
            height = width*scale;
        }else{
            CGFloat scale = width/height;
            height = 1280;
            width = height*scale;
        }
        //2.宽大于1280高小于1280
    }else if(width>1280||height<1280){
        CGFloat scale = height/width;
        width = 1280;
        height = width*scale;
        //3.宽小于1280高大于1280
    }else if(width<1280||height>1280){
        CGFloat scale = width/height;
        height = 1280;
        width = height*scale;
        //4.宽高都小于1280
    }else{
        
    }
    //进行尺寸重绘
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    [sourceImage drawInRect:CGRectMake(0,0,width,height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSLog(@"图像尺寸压缩后 %.2f M width %.2f height %.2f",data.length/1024.f/1024.f,width,height);
    
    return newImage;
}


+ (NSData *)zipNSDataWithImage:(UIImage *)sourceImage{
    NSData *data = UIImageJPEGRepresentation(sourceImage, 1.0);
    NSLog(@"图像质量压缩前 %.2f M",data.length/1024.f/1024.f);
    if (data.length>100*1024) {
        if (data.length>6*1024*1024) {//6M以及以上
            data = UIImageJPEGRepresentation(sourceImage, 0.2);
            
        }else if (data.length>3*1024*1024) {//3M以及以上
            data = UIImageJPEGRepresentation(sourceImage, 0.3);
            
        }else if (data.length>1024*1024) {//1M以及以上
            data = UIImageJPEGRepresentation(sourceImage, 0.5);
            
        }else if (data.length>512*1024) {//0.5M-1M
            data = UIImageJPEGRepresentation(sourceImage, 0.6);
            
        }else if (data.length>200*1024) {//0.25M-0.5M
            data = UIImageJPEGRepresentation(sourceImage, 0.7);
        }
    }
    NSLog(@"图像质量压缩后 %.2f M",data.length/1024.f/1024.f);
    return data;
}

+ (void)uploadPhotos:(NSMutableArray <OSSPhotoObj *>*)photos
            complete:(void(^)(UploadImageState state))complete{
    
    [[AliyunOSSDemo sharedInstance] setupEnvironment];
    
    NSInteger allImageCount = photos.count;
    __block int uploadCount = 0;
    __block UploadImageState uploadState = UploadImageSuccess;

    for(OSSPhotoObj *obj in photos) {
        NSData *uploadingData = [self zipNSDataWithImage:obj.photo];

        OSSPutObjectRequest * put = [OSSPutObjectRequest new];
        put.bucketName = @"oss_bucket";
        put.objectKey = obj.objectKey;
        put.uploadingData = uploadingData;
        
        OSSTask * putTask = [client putObject:put];
        [putTask continueWithBlock:^id(OSSTask *task) {
            uploadCount++;
            if (!task.error) {
                NSLog(@"upload object success! url+objectKey: \n%@%@",@"http://xxx.oss-cn-beijing.aliyuncs.com/",put.objectKey);
                
            }else{
                NSLog(@"upload object failed, error: %@" , task.error);
                uploadState = UploadImageFail;
            }

            if (uploadCount >= allImageCount) {
                if (complete) {
                    complete(uploadState);
                }
            }
            return nil;
        }];
    }
}

+ (void)uploadImageDic:(NSDictionary *)imageDic
               isAsync:(BOOL)isAsync
              complete:(void(^)(UploadImageState state))complete{
    
    [[AliyunOSSDemo sharedInstance] setupEnvironment];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    NSArray *objectKeys = [imageDic allKeys];

    queue.maxConcurrentOperationCount = objectKeys.count;
    
    int i = 0;
    __block UploadImageState uploadState = UploadImageSuccess;
    for (NSString *objectKey in objectKeys) {
        UIImage *image = [imageDic objectForKey:objectKey];
        if (image) {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                
                OSSPutObjectRequest * put = [OSSPutObjectRequest new];
                put.bucketName = @"oss_bucket";
                put.objectKey = objectKey;

                // 压缩
                NSData *uploadingData = UIImageJPEGRepresentation(image, 0.6);

                put.uploadingData = uploadingData; // 直接上传NSData
                
                OSSTask * putTask = [client putObject:put];
                [putTask waitUntilFinished]; // 阻塞直到上传完成
                if (!putTask.error) {
                    NSLog(@"upload object success! objectKey %@",objectKey);
                } else {
                    NSLog(@"upload object failed, error: %@" , putTask.error);
                    uploadState = UploadImageFail;
                }
                
                if (isAsync) {
                    if (objectKey == objectKeys.lastObject) {
                        NSLog(@"upload object finished! lastObject %@",objectKey);
                        if (complete) {
                            complete(uploadState);
                        }
                    }
                }
                
            }];
            if (queue.operations.count != 0) {
                [operation addDependency:queue.operations.lastObject];
            }
            [queue addOperation:operation];
        }
        i++;
    }
    if (!isAsync) {
        [queue waitUntilAllOperationsAreFinished];
        if (complete) {
            if (complete) {
                complete(uploadState);
            }
        }
    }
}

// 异步上传
- (void)uploadObjectAsync {
    OSSPutObjectRequest * put = [OSSPutObjectRequest new];

    // 必填字段
    put.bucketName = @"oss_bucket";
    
//    在上传文件是，如果把ObjectKey写为"folder/subfolder/file"，即是模拟了把文件上传到folder/subfolder/下的file文件。注意，路径默认是”根目录”，不需要以’/‘开头
    
    put.objectKey = @"file1m";
    
    NSString * docDir = [self getDocumentDirectory];
    put.uploadingFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:@"file1m"]];
    // put.uploadingData = <NSData *>; // 直接上传NSData

    
    // 可选字段，可不设置
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    
//    put.contentType = @"";
//    put.contentMd5 = @"";
//    put.contentEncoding = @"";
//    put.contentDisposition = @"";
    // put.objectMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value1", @"x-oss-meta-name1", nil]; // 可以在上传时设置元信息或者其他HTTP头部

    OSSTask * putTask = [client putObject:put];

    [putTask continueWithBlock:^id(OSSTask *task) {
        NSLog(@"objectKey: %@", put.objectKey);
        if (!task.error) {
            NSLog(@"upload object success!");
        } else {
            NSLog(@"upload object failed, error: %@" , task.error);
        }
        return nil;
    }];
}

// 同步上传
- (void)uploadObjectSync {
    OSSPutObjectRequest * put = [OSSPutObjectRequest new];

    // required fields
    put.bucketName = @"android-test";
    put.objectKey = @"file1m";
    NSString * docDir = [self getDocumentDirectory];
    put.uploadingFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:@"file1m"]];

    // optional fields
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    put.contentType = @"";
    put.contentMd5 = @"";
    put.contentEncoding = @"";
    put.contentDisposition = @"";

    OSSTask * putTask = [client putObject:put];

    [putTask waitUntilFinished]; // 阻塞直到上传完成

    if (!putTask.error) {
        NSLog(@"upload object success!");
    } else {
        NSLog(@"upload object failed, error: %@" , putTask.error);
    }
}

// 追加上传

- (void)appendObject {
    OSSAppendObjectRequest * append = [OSSAppendObjectRequest new];

    // 必填字段
    append.bucketName = @"android-test";
    append.objectKey = @"file1m";
    append.appendPosition = 0; // 指定从何处进行追加
    NSString * docDir = [self getDocumentDirectory];
    append.uploadingFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:@"file1m"]];

    // 可选字段
    append.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    // append.contentType = @"";
    // append.contentMd5 = @"";
    // append.contentEncoding = @"";
    // append.contentDisposition = @"";

    OSSTask * appendTask = [client appendObject:append];

    [appendTask continueWithBlock:^id(OSSTask *task) {
        NSLog(@"objectKey: %@", append.objectKey);
        if (!task.error) {
            NSLog(@"append object success!");
            OSSAppendObjectResult * result = task.result;
            NSString * etag = result.eTag;
            long nextPosition = result.xOssNextAppendPosition;
            NSLog(@"etag: %@, nextPosition: %ld", etag, nextPosition);
        } else {
            NSLog(@"append object failed, error: %@" , task.error);
        }
        return nil;
    }];
}

// 异步下载
- (void)downloadObjectAsync {
    OSSGetObjectRequest * request = [OSSGetObjectRequest new];
    // required
    request.bucketName = @"android-test";
    request.objectKey = @"file1m";

    //optional
    request.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"%lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    // NSString * docDir = [self getDocumentDirectory];
    // request.downloadToFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:@"downloadfile"]];

    OSSTask * getTask = [client getObject:request];

    [getTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"download object success!");
            OSSGetObjectResult * getResult = task.result;
            NSLog(@"download dota length: %lu", [getResult.downloadedData length]);
        } else {
            NSLog(@"download object failed, error: %@" ,task.error);
        }
        return nil;
    }];
}

// 同步下载
- (void)downloadObjectSync {
    OSSGetObjectRequest * request = [OSSGetObjectRequest new];
    // required
    request.bucketName = @"android-test";
    request.objectKey = @"file1m";

    //optional
    request.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"%lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    // NSString * docDir = [self getDocumentDirectory];
    // request.downloadToFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:@"downloadfile"]];

    OSSTask * getTask = [client getObject:request];

    [getTask waitUntilFinished];

    if (!getTask.error) {
        OSSGetObjectResult * result = getTask.result;
        NSLog(@"download data length: %lu", [result.downloadedData length]);
    } else {
        NSLog(@"download data error: %@", getTask.error);
    }
}

// 获取meta
- (void)headObject {
    OSSHeadObjectRequest * head = [OSSHeadObjectRequest new];
    head.bucketName = @"android-test";
    head.objectKey = @"file1m";

    OSSTask * headTask = [client headObject:head];

    [headTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            OSSHeadObjectResult * headResult = task.result;
            NSLog(@"all response header: %@", headResult.httpResponseHeaderFields);

            // some object properties include the 'x-oss-meta-*'s
            NSLog(@"head object result: %@", headResult.objectMeta);
        } else {
            NSLog(@"head object error: %@", task.error);
        }
        return nil;
    }];
}

// 删除Object
- (void)deleteObject {
    OSSDeleteObjectRequest * delete = [OSSDeleteObjectRequest new];
    delete.bucketName = @"android-test";
    delete.objectKey = @"file1m";

    OSSTask * deleteTask = [client deleteObject:delete];

    [deleteTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"delete success !");
        } else {
            NSLog(@"delete erorr, error: %@", task.error);
        }
        return nil;
    }];
}

// 复制Object
- (void)copyObjectAsync {
    OSSCopyObjectRequest * copy = [OSSCopyObjectRequest new];
    copy.bucketName = @"android-test"; // 复制到哪个bucket
    copy.objectKey = @"file_copy_to"; // 复制为哪个object
    copy.sourceCopyFrom = [NSString stringWithFormat:@"/%@/%@", @"android-test", @"file1m"]; // 从哪里复制

    OSSTask * copyTask = [client copyObject:copy];

    [copyTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"copy success!");
        } else {
            NSLog(@"copy error, error: %@", task.error);
        }
        return nil;
    }];
}

// 签名URL授予第三方访问
- (void)signAccessObjectURL {
    NSString * constrainURL = nil;
    NSString * publicURL = nil;

    // sign constrain url
    OSSTask * task = [client presignConstrainURLWithBucketName:@"<bucket name>"
                                                 withObjectKey:@"<object key>"
                                        withExpirationInterval:60 * 30];
    if (!task.error) {
        constrainURL = task.result;
    } else {
        NSLog(@"error: %@", task.error);
    }

    // sign public url
    task = [client presignPublicURLWithBucketName:@"<bucket name>"
                                    withObjectKey:@"<object key>"];
    if (!task.error) {
        publicURL = task.result;
    } else {
        NSLog(@"sign url error: %@", task.error);
    }
}

// 分块上传
- (void)multipartUpload {

    __block NSString * uploadId = nil;
    __block NSMutableArray * partInfos = [NSMutableArray new];

    NSString * uploadToBucket = @"android-test";
    NSString * uploadObjectkey = @"file20m";

    OSSInitMultipartUploadRequest * init = [OSSInitMultipartUploadRequest new];
    init.bucketName = uploadToBucket;
    init.objectKey = uploadObjectkey;
    init.contentType = @"application/octet-stream";
    init.objectMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value1", @"x-oss-meta-name1", nil];

    OSSTask * initTask = [client multipartUploadInit:init];

    [initTask waitUntilFinished];

    if (!initTask.error) {
        OSSInitMultipartUploadResult * result = initTask.result;
        uploadId = result.uploadId;
        NSLog(@"init multipart upload success: %@", result.uploadId);
    } else {
        NSLog(@"multipart upload failed, error: %@", initTask.error);
        return;
    }

    for (int i = 1; i <= 20; i++) {
        @autoreleasepool {
            OSSUploadPartRequest * uploadPart = [OSSUploadPartRequest new];
            uploadPart.bucketName = uploadToBucket;
            uploadPart.objectkey = uploadObjectkey;
            uploadPart.uploadId = uploadId;
            uploadPart.partNumber = i; // part number start from 1

            NSString * docDir = [self getDocumentDirectory];
            // uploadPart.uploadPartFileURL = [NSURL URLWithString:[docDir stringByAppendingPathComponent:@"file1m"]];
            uploadPart.uploadPartData = [NSData dataWithContentsOfFile:[docDir stringByAppendingPathComponent:@"file1m"]];

            OSSTask * uploadPartTask = [client uploadPart:uploadPart];

            [uploadPartTask waitUntilFinished];

            if (!uploadPartTask.error) {
                OSSUploadPartResult * result = uploadPartTask.result;
                uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:uploadPart.uploadPartFileURL.absoluteString error:nil] fileSize];
                [partInfos addObject:[OSSPartInfo partInfoWithPartNum:i eTag:result.eTag size:fileSize]];
            } else {
                NSLog(@"upload part error: %@", uploadPartTask.error);
                return;
            }
        }
    }

    OSSCompleteMultipartUploadRequest * complete = [OSSCompleteMultipartUploadRequest new];
    complete.bucketName = uploadToBucket;
    complete.objectKey = uploadObjectkey;
    complete.uploadId = uploadId;
    complete.partInfos = partInfos;

    OSSTask * completeTask = [client completeMultipartUpload:complete];

    [completeTask waitUntilFinished];

    if (!completeTask.error) {
        NSLog(@"multipart upload success!");
    } else {
        NSLog(@"multipart upload failed, error: %@", completeTask.error);
        return;
    }
}

// 罗列分块
- (void)listParts {
    OSSListPartsRequest * listParts = [OSSListPartsRequest new];
    listParts.bucketName = @"android-test";
    listParts.objectKey = @"file3m";
    listParts.uploadId = @"265B84D863B64C80BA552959B8B207F0";

    OSSTask * listPartTask = [client listParts:listParts];

    [listPartTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"list part result success!");
            OSSListPartsResult * listPartResult = task.result;
            for (NSDictionary * partInfo in listPartResult.parts) {
                NSLog(@"each part: %@", partInfo);
            }
        } else {
            NSLog(@"list part result error: %@", task.error);
        }
        return nil;
    }];
}

// 断点续传
- (void)resumableUpload {
    __block NSString * recordKey;

    NSString * docDir = [self getDocumentDirectory];
    NSString * filePath = [docDir stringByAppendingPathComponent:@"file10m"];
    NSString * bucketName = @"android-test";
    NSString * objectKey = @"uploadKey";

    [[[[[[OSSTask taskWithResult:nil] continueWithBlock:^id(OSSTask *task) {
        // 为该文件构造一个唯一的记录键
        NSURL * fileURL = [NSURL fileURLWithPath:filePath];
        NSDate * lastModified;
        NSError * error;
        [fileURL getResourceValue:&lastModified forKey:NSURLContentModificationDateKey error:&error];
        if (error) {
            return [OSSTask taskWithError:error];
        }
        recordKey = [NSString stringWithFormat:@"%@-%@-%@-%@", bucketName, objectKey, [OSSUtil getRelativePath:filePath], lastModified];
        // 通过记录键查看本地是否保存有未完成的UploadId
        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
        return [OSSTask taskWithResult:[userDefault objectForKey:recordKey]];
    }] continueWithSuccessBlock:^id(OSSTask *task) {
        if (!task.result) {
            // 如果本地尚无记录，调用初始化UploadId接口获取
            OSSInitMultipartUploadRequest * initMultipart = [OSSInitMultipartUploadRequest new];
            initMultipart.bucketName = bucketName;
            initMultipart.objectKey = objectKey;
            initMultipart.contentType = @"application/octet-stream";
            return [client multipartUploadInit:initMultipart];
        }
        OSSLogVerbose(@"An resumable task for uploadid: %@", task.result);
        return task;
    }] continueWithSuccessBlock:^id(OSSTask *task) {
        NSString * uploadId = nil;

        if (task.error) {
            return task;
        }

        if ([task.result isKindOfClass:[OSSInitMultipartUploadResult class]]) {
            uploadId = ((OSSInitMultipartUploadResult *)task.result).uploadId;
        } else {
            uploadId = task.result;
        }

        if (!uploadId) {
            return [OSSTask taskWithError:[NSError errorWithDomain:OSSClientErrorDomain
                                                             code:OSSClientErrorCodeNilUploadid
                                                         userInfo:@{OSSErrorMessageTOKEN: @"Can't get an upload id"}]];
        }
        // 将“记录键：UploadId”持久化到本地存储
        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:uploadId forKey:recordKey];
        [userDefault synchronize];
        return [OSSTask taskWithResult:uploadId];
    }] continueWithSuccessBlock:^id(OSSTask *task) {
        // 持有UploadId上传文件
        OSSResumableUploadRequest * resumableUpload = [OSSResumableUploadRequest new];
        resumableUpload.bucketName = bucketName;
        resumableUpload.objectKey = objectKey;
        resumableUpload.uploadId = task.result;
        resumableUpload.uploadingFileURL = [NSURL fileURLWithPath:filePath];
        resumableUpload.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            NSLog(@"%lld %lld %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
        };
        return [client resumableUpload:resumableUpload];
    }] continueWithBlock:^id(OSSTask *task) {
        if (task.error) {
            if ([task.error.domain isEqualToString:OSSClientErrorDomain] && task.error.code == OSSClientErrorCodeCannotResumeUpload) {
                // 如果续传失败且无法恢复，需要删除本地记录的UploadId，然后重启任务
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:recordKey];
            }
        } else {
            NSLog(@"upload completed!");
            // 上传成功，删除本地保存的UploadId
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:recordKey];
        }
        return nil;
    }];
}
@end
