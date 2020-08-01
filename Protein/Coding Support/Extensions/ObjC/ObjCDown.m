//
//  ObjCDown.m
//  Downloader
//
//  Created by Lakr Aream on 2020/4/13.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import "ObjCDown.h"

@implementation ObjCDown 

+ (instancetype)shared {
    static ObjCDown *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ObjCDown alloc] init];
        NSString* docDir = [[[[NSFileManager defaultManager]
                             URLsForDirectory:NSDocumentDirectory
                             inDomains:NSUserDomainMask] lastObject] absoluteString];
        docDir = [docDir substringFromIndex:7];
        if ([[NSFileManager defaultManager] fileExistsAtPath:docDir]) {
            shared->sharedTempDir  = [[NSString alloc] initWithFormat:@"%@/wiki.qaq.Protein/Downloads", docDir];
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:shared->sharedTempDir  isDirectory:&isDir]) {
                assert(isDir);
            } else {
                NSError *err;
                [[NSFileManager defaultManager] createDirectoryAtPath:shared->sharedTempDir
                                          withIntermediateDirectories:YES attributes:NULL error:&err];
                assert(!err);
            }
        } else {
            shared->sharedTempDir  = [[NSString alloc] initWithFormat:@"/var/mobile/Downloads/"];
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:[shared->sharedTempDir stringByAppendingString:@"/Caches"]
                                  withIntermediateDirectories:YES
                                                   attributes:NULL
                                                        error:NULL];
        NSLog(@"[ObjCDown] Set download dir %@\n", shared->sharedTempDir);
        shared->sharedCacheRecordLocation = [shared->sharedTempDir stringByAppendingString:@"/Records.txt"];
        
        // 由于模拟器会重置存档目录 所以检测缓存的记录 如果位置已经不存在了 就删掉缓存
        NSString* context = [NSString stringWithContentsOfFile:shared->sharedCacheRecordLocation
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        if (context) {
            NSString* newContext = @"";
            NSArray<NSString *>* compoments = [context componentsSeparatedByString:@"\n"];
            for (int i = 0; i < [compoments count]; i++) {
                NSString* item = [compoments objectAtIndex:i];
                // 切分
                NSArray<NSString *>* seped = [item componentsSeparatedByString:@"|"];
                if ([seped count] != 2)
                    continue;
                NSString* fileLocation = [seped lastObject];
                if (![NSFileManager.defaultManager fileExistsAtPath:fileLocation])
                    continue;
                newContext = [newContext stringByAppendingString:item];
            }
            [[NSFileManager defaultManager] removeItemAtPath:shared->sharedCacheRecordLocation error:NULL];
            [newContext writeToFile:shared->sharedCacheRecordLocation atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        }
        
    });
    return shared;
}

// ---------------------------------------------------

- (NSString*)getSharedTempDir {
    return [sharedTempDir mutableCopy];
}

- (void)saveRecordLine:(NSString *)str {
    NSString* location = self->sharedCacheRecordLocation;
    NSString* context = [NSString stringWithContentsOfFile:location
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    if (!context)
        context = @"";
    context = [context stringByAppendingString:@"\n"];
    context = [context stringByAppendingString:str];
    [[NSFileManager defaultManager] removeItemAtPath:location error:NULL];
    [context writeToFile:location atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

- (void)deleteRecordWithURL:(NSURL*)url {
    NSString* location = self->sharedCacheRecordLocation;
    NSString* context = [NSString stringWithContentsOfFile:location
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    if (!context)
        return;
    NSString* newContext = @"";
    NSArray<NSString *>* compoments = [context componentsSeparatedByString:@"\n"];
    for (int i = 0; i < [compoments count]; i++) {
        NSString* item = [compoments objectAtIndex:i];
        // 切分
        NSArray<NSString *>* seped = [item componentsSeparatedByString:@"|"];
        if ([seped count] != 2)
            continue;
        NSString* link = [seped firstObject];
//        NSString* loca = [seped lastObject];
        if ([link isEqualToString:[url absoluteString]])
            continue;
        newContext = [newContext stringByAppendingString:item];
    }
    [[NSFileManager defaultManager] removeItemAtPath:location error:NULL];
    [newContext writeToFile:location atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

- (NSString* _Nullable)getCacheFileWithURL:(NSURL*)url {
    NSString* location = self->sharedCacheRecordLocation;
    NSString* context = [NSString stringWithContentsOfFile:location
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSArray<NSString *>* compoments = [context componentsSeparatedByString:@"\n"];
    for (int i = 0; i < [compoments count]; i++) {
        NSString* item = [compoments objectAtIndex:i];
        // 切分
        NSArray<NSString *>* seped = [item componentsSeparatedByString:@"|"];
        if ([seped count] != 2)
            continue;
        NSString* link = [seped firstObject];
        NSString* loca = [seped lastObject];
        if ([link isEqualToString:[url absoluteString]])
            return loca;
    }
    return NULL;
}

- (NSURLSessionTask*)downlodFrom:(NSURL*)url toLocation:(NSURL*)fileLocation
                     withHeaders:(NSDictionary*)dic
                      onProgress:(void (^)(float downloadProgress))callProgress
                      onFinish:(void (^)(void))callFinish {
    
    // 检查缓存是否存在
    NSString* lastCache = [self getCacheFileWithURL:url];
    NSURL* downloadCacheLocation;
    if (lastCache) {
        downloadCacheLocation = [NSURL fileURLWithPath:lastCache];
    } else {
        // 分配缓存位置
        CFUUIDRef uuid_ = CFUUIDCreate(NULL);
        NSString* uuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid_));
        uuid = [uuid stringByAppendingString:@".dlc"];
        downloadCacheLocation = [NSURL fileURLWithPath:[sharedTempDir
                                      stringByAppendingString:@"/Caches"]];
        downloadCacheLocation = [downloadCacheLocation URLByAppendingPathComponent:uuid];
        // 记录当前缓存
        NSString* recordDes = [[NSString alloc] initWithFormat:@"%@|%@", [url absoluteString],
                               [[downloadCacheLocation absoluteString] substringFromIndex:7]];
        [self saveRecordLine:recordDes];
    }
    
    NSString* downloadCacheLocationString = [[downloadCacheLocation absoluteString] substringFromIndex:7];
    
    // Log
    NSLog(@"Download from %@ to %@", [url absoluteString], downloadCacheLocationString);
    
    // 初始化下载
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager* manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    for (id key in dic) {
        [request setValue:[dic objectForKey:key] forHTTPHeaderField:key];
    }
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    // 读取缓存文件
    NSData* cacheData = [NSData dataWithContentsOfURL:downloadCacheLocation];
    
    // 如果连2都没有那就重新下载吧 Ps. > 0 感觉不安全
    if ([cacheData length] < 2 ||
        ![[NSFileManager defaultManager] fileExistsAtPath: downloadCacheLocationString]) {
        // 重新/创建文件
        [[NSFileManager defaultManager] createFileAtPath: downloadCacheLocationString contents:NULL attributes:NULL];
    }

    __block NSInteger currentLenth = [cacheData length];
    __block NSInteger fullLenth = -1; // 如果没有预计长度大概就是需要重新下载的
    __block NSFileHandle* handler;
    __block BOOL completed = false;
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", currentLenth];
    [request setValue:range forHTTPHeaderField:@"Range"];
    // 请求数据 在写入block写入 在完成block拷贝文件到目的地
    NSURLSessionDataTask* task = [manager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    }
                                             downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        // 这里不计算 在DataTask去计算
    }
                                            completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        // 关闭文件句柄
        [handler closeFile];
        completed = true;
        // 这里是下载完成的回掉
        if (error) {
            NSLog(@"Task to: %@ failed!\n    -> %@\n", url, [error localizedDescription]);
            // 删除缓存文件 先不删除吧 可能可以继续下载
            callFinish();
            return;
        }
        // 下载目标目录是否存在？
        NSString* destDir = [[[fileLocation absoluteString] substringFromIndex:5] stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:destDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:destDir
                                      withIntermediateDirectories:YES attributes:NULL error:NULL];
        }
        // 移动文件
        NSString* destString = [[fileLocation absoluteString] substringFromIndex:7];
        [NSFileManager.defaultManager moveItemAtPath:downloadCacheLocationString toPath:destString error:NULL];
        // 该删除缓存了
        [self deleteRecordWithURL: url];
        // 传回完成调用
        callFinish();
    }];
    [manager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        // 计算总长度
        fullLenth = response.expectedContentLength + currentLenth;
        // 由于currentlenth一定大于0所以就简单处理文件了
        handler = [NSFileHandle fileHandleForWritingAtPath:downloadCacheLocationString];
        return NSURLSessionResponseAllow;
    }];
    
    __block float progCache = 0;
    
    [manager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        // 写入数据并且汇报进度
        [handler seekToEndOfFile];
        [handler writeData:data];
        currentLenth += [data length];
        // 计算进度
        progCache = 1.0f * currentLenth / fullLenth;
        // 汇报进度
//        NSLog(@" -> %f\n", prog);
    }];
    [task resume];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        while (!completed) {
            if (callProgress)
                callProgress(progCache);
        }
    });
    
    return task;
}


@end
