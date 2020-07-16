//
//  BZipCompression.m
//  BZipCompression
//
//  Created by Blake Watters on 9/19/13.
//  Copyright (c) 2013 Blake Watters. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <bzlib.h>
#import "BZipCompression.h"

NSString * const BZipErrorDomain = @"com.blakewatters.BZipCompression";
static const char *BZipCompressionQueueLabel = "com.blakewatters.BZipCompression.compressionQueue";
static NSUInteger const BZipCompressionBufferSize = 1024;
NSInteger const BZipDefaultBlockSize = 7;
NSInteger const BZipDefaultWorkFactor = 0;

@implementation BZipCompression

+ (NSData *)compressedDataWithData:(NSData *)data blockSize:(NSInteger)blockSize workFactor:(NSInteger)workFactor error:(NSError **)error
{
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorNilInputDataError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Input data cannot be `nil`.", nil) }];
        }
        return nil;
    }
    if ([data length] == 0) return data;

    bz_stream stream;
    bzero(&stream, sizeof(stream));
    stream.next_in = (char *)[data bytes];
    stream.avail_in = [data length];

    NSMutableData *buffer = [NSMutableData dataWithLength:BZipCompressionBufferSize];
    stream.next_out = [buffer mutableBytes];
    stream.avail_out = BZipCompressionBufferSize;

    int bzret;
    bzret = BZ2_bzCompressInit(&stream, blockSize, 0, workFactor);
    if (bzret != BZ_OK) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzCompressInit` failed", nil) }];
        }
        return nil;
    }

    NSMutableData *compressedData = [NSMutableData data];
    do {
        bzret = BZ2_bzCompress(&stream, (stream.avail_in) ? BZ_RUN : BZ_FINISH);
        if (bzret < BZ_OK) {
            if (error) {
                *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzCompress` failed", nil) }];
            }
            return nil;
        }

        [compressedData appendBytes:[buffer bytes] length:(BZipCompressionBufferSize - stream.avail_out)];
        stream.next_out = [buffer mutableBytes];
        stream.avail_out = BZipCompressionBufferSize;
    } while (bzret != BZ_STREAM_END);

    BZ2_bzCompressEnd(&stream);

    return compressedData;
}

+ (NSData *)decompressedDataWithData:(NSData *)data error:(NSError **)error
{
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorNilInputDataError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Input data cannot be `nil`.", nil) }];
        }
        return nil;
    }
    if ([data length] == 0) return data;

    bz_stream stream;
    bzero(&stream, sizeof(stream));
    stream.next_in = (char *)[data bytes];
    stream.avail_in = [data length];

    NSMutableData *buffer = [NSMutableData dataWithLength:BZipCompressionBufferSize];
    stream.next_out = [buffer mutableBytes];
    stream.avail_out = BZipCompressionBufferSize;

    int bzret;
    bzret = BZ2_bzDecompressInit(&stream, 0, NO);
    if (bzret != BZ_OK) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzDecompressInit` failed", nil) }];
        }
        return nil;
    }

    NSMutableData *decompressedData = [NSMutableData data];
    do {
        bzret = BZ2_bzDecompress(&stream);
        if (bzret < BZ_OK) {
            if (error) {
                *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzDecompress` failed", nil) }];
            }
            return nil;
        }

        [decompressedData appendBytes:[buffer bytes] length:(BZipCompressionBufferSize - stream.avail_out)];
        stream.next_out = [buffer mutableBytes];
        stream.avail_out = BZipCompressionBufferSize;
    } while (bzret != BZ_STREAM_END);

    BZ2_bzDecompressEnd(&stream);
    
    return decompressedData;
}

+ (BOOL)decompressDataFromFileAtPath:(NSString *)sourcePath toFileAtPath:(NSString *)destinationPath error:(NSError **)error
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    __block NSError *outputError = nil;
    [self asynchronouslyDecompressFileAtPath:sourcePath toFileAtPath:destinationPath progress:nil completion:^(BOOL completionSuccess, NSError *completionError) {
        success = completionSuccess;
        outputError = completionError;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (error) {
        *error = outputError;
    }
    return success;
}

+ (void)asynchronouslyDecompressFileAtPath:(NSString *)sourcePath toFileAtPath:(NSString *)destinationPath progress:(NSProgress **)progress completion:(void (^)(BOOL success, NSError *error))completion
{
    __block NSError *error = nil;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:sourcePath isDirectory:&isDirectory]) {
        error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidSourcePath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the source path given does not exist.", nil) }];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    if (isDirectory) {
        error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidSourcePath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the source path given is a directory.", nil) }];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isDirectory]) {
        error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the destination path given already exists.", nil) }];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    if (isDirectory) {
        error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the destination path given is a directory.", nil) }];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    NSError *attributesError = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:sourcePath error:&attributesError];
    if (!attributes) {
        error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorFileManagementFailure userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the size of the source path .", nil), NSUnderlyingErrorKey: attributesError }];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    unsigned long long sourceFileSize = [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
    
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
    if (!success) {
        error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorUnableToCreateDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the destination path could not be created.", nil) }];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    NSProgress *decompressionProgress = [NSProgress progressWithTotalUnitCount:sourceFileSize];
    decompressionProgress.kind = NSProgressKindFile;
    decompressionProgress.cancellable = YES;
    decompressionProgress.pausable = NO;
    if (progress) {
        *progress = decompressionProgress;
    }
    
    dispatch_queue_t decompressionQueue = dispatch_queue_create(BZipCompressionQueueLabel, DISPATCH_QUEUE_SERIAL);
    dispatch_async(decompressionQueue, ^{
        unsigned long long totalBytesProcessed = 0;
        
        bz_stream stream;
        bzero(&stream, sizeof(stream));
        NSFileHandle *inputFileHandle = [NSFileHandle fileHandleForReadingAtPath:sourcePath];
        if (!inputFileHandle) {
            error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidSourcePath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because a readable file handle for the source path could not be created.", nil) }];
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
        if (!outputFileHandle) {
            error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because a writable file handle for the destination path could not be created.", nil) }];
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSMutableData *compressedDataBuffer = [NSMutableData new];
        int bzret = BZ_OK;
        bzret = BZ2_bzDecompressInit(&stream, 0, NO);
        if (bzret != BZ_OK) {
            error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because `BZ2_bzDecompressInit` returned an error.", nil) }];
        } else {
            while (true) {
                if (decompressionProgress.isCancelled) {
                    error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorOperationCancelled userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the operation was cancelled.", nil) }];
                    break;
                }
                NSData *inputChunk = [inputFileHandle readDataOfLength:BZipCompressionBufferSize];
                if ([inputChunk length] == 0) {
                    // No data left to read -- all done
                    break;
                }
                [compressedDataBuffer appendData:inputChunk];
                
                totalBytesProcessed += [inputChunk length];
                [decompressionProgress setCompletedUnitCount:totalBytesProcessed];
                stream.next_in = (char *)[compressedDataBuffer bytes];
                stream.avail_in = [compressedDataBuffer length];
                
                NSMutableData *decompressedDataBuffer = [NSMutableData dataWithLength:BZipCompressionBufferSize];
                while (true) {
                    stream.next_out = [decompressedDataBuffer mutableBytes];
                    stream.avail_out = BZipCompressionBufferSize;
                    
                    bzret = BZ2_bzDecompress(&stream);
                    if (bzret < BZ_OK) {
                        error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because `BZ2_bzDecompress` returned an error.", nil) }];
                        break;
                    }
                    NSData *decompressedData = [NSMutableData dataWithBytes:[decompressedDataBuffer bytes] length:(BZipCompressionBufferSize - stream.avail_out)];
                    [outputFileHandle writeData:decompressedData];
                    
                    if ((BZipCompressionBufferSize - stream.avail_out) == 0) {
                        // Save the remaining bits for the next iteration
                        [compressedDataBuffer setData:[NSData dataWithBytes:stream.next_in length:stream.avail_in]];
                        break;
                    }
                    
                    if (bzret == BZ_STREAM_END) {
                        break;
                    }
                }
                
                if (bzret == BZ_STREAM_END || error) {
                    break;
                }
            }
            
            BZ2_bzDecompressEnd(&stream);
        }
        
        [inputFileHandle closeFile];
        [outputFileHandle closeFile];
        
        if (error) {
            [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
        }
        if (completion) {
            completion(error == nil, error);
        }
    });
}

@end
