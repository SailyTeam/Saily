//
//  ObjCDown.h
//  Downloader
//
//  Created by Lakr Aream on 2020/4/13.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AFNetworking/AFNetworking.h"

NS_ASSUME_NONNULL_BEGIN

#define DEFAULT_DOWNLOAD_LOCATION @"/var/mobile/Downloads"
#define DEFAULT_DOWNLOAD_RECORD_LOCATION @"/var/mobile/Downloads/cache/record.txt"

@interface ObjCDown : NSObject {

    // 缓存的位置
    NSString* sharedTempDir;
    // 缓存记录的位置
    NSString* sharedCacheRecordLocation;
    
}

// 共享的实例 调用会初始化缓存位置
+ (instancetype)shared;

- (NSString*)getSharedTempDir;
// 记录缓存行
- (void)saveRecordLine:(NSString *)str;
// 查询缓存
- (NSString* _Nullable)getCacheFileWithURL:(NSURL*)url;
// 使用远程url删除缓存行
- (void)deleteRecordWithURL:(NSURL*)url;

// 使用本下载自带缓存逻辑 哪怕你的App重启了 只要缓存记录不被删除就能断点续传
- (NSURLSessionTask*)downlodFrom:(NSURL*)url toLocation:(NSURL*)fileLocation
                     withHeaders:(NSDictionary*)dic
                      onProgress:(void (^)(float downloadProgress))callProgress
                        onFinish:(void (^)(void))callFinish ;
@end

NS_ASSUME_NONNULL_END
