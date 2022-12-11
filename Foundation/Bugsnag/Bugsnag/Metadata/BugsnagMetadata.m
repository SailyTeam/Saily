//
//  BugsnagMetaData.m
//
//  Created by Conrad Irwin on 2014-10-01.
//
//  Copyright (c) 2014 Bugsnag, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "BugsnagMetadata+Private.h"

#import "BSGJSONSerialization.h"
#import "BSGSerialization.h"
#import "BSGUtils.h"
#import "BugsnagLogger.h"


BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagMetadata ()

@property(atomic, readwrite, strong) NSMutableArray *stateEventBlocks;

@property (assign, nonatomic) char **buffer;
@property (copy, nonatomic) NSString *file;
@property (copy, nonatomic) NSData *pendingWrite;

@end


// MARK: -

BSG_OBJC_DIRECT_MEMBERS
@implementation BugsnagMetadata

- (instancetype)init {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    return [self initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if ((self = [super init])) {
        // Ensure that the instantiating dictionary is mutable.
        // Saves checks later.
        _dictionary = BSGSanitizeDict(dict);
        self.stateEventBlocks = [NSMutableArray new];
    }
    if (self.observer) {
        self.observer(self);
    }
    return self;
}

- (NSDictionary *)toDictionary {
    @synchronized (self) {
        return [self.dictionary mutableCopy];
    }
}

// MARK: - <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    @synchronized(self) {
        return [[BugsnagMetadata allocWithZone:zone] initWithDictionary:self.dictionary];
    }
}

- (NSMutableDictionary *)getMetadata:(NSString *)sectionName {
    @synchronized(self) {
        return self.dictionary[sectionName];
    }
}

- (NSMutableDictionary *)getMetadata:(NSString *)sectionName
                                 key:(NSString *)key
{
    @synchronized(self) {
        return self.dictionary[sectionName][key];
    }
}

// MARK: - <BugsnagMetadataStore>

/**
 * Add a single key/value to a metadata Tab/Section.
 */
- (void)addMetadata:(id)metadata
            withKey:(NSString *)key
          toSection:(NSString *)sectionName
{
    if (key) {
        [self addMetadata:@{key: metadata ?: [NSNull null]} toSection:sectionName];
    }
}

/**
 * Merge supplied and existing metadata.
 */
- (void)addMetadata:(NSDictionary *)metadataValues
          toSection:(NSString *)sectionName
{
    @synchronized (self) {
        NSDictionary *oldValue = self.dictionary[sectionName] ?: @{};
        NSMutableDictionary *metadata = [oldValue mutableCopy];
        for (id key in metadataValues) {
            if ([key isKindOfClass:[NSString class]]) {
                id obj = metadataValues[key];
                if (obj == [NSNull null]) {
                    metadata[key] = nil;
                } else {
                    id sanitisedObject = BSGSanitizeObject(obj);
                    if (sanitisedObject) {
                        metadata[key] = sanitisedObject;
                    } else {
                        bsg_log_err(@"Failed to add metadata: %@ is not JSON serializable.", [obj class]);
                    }
                }
            }
        }
        if (![oldValue isEqual:metadata]) {
            self.dictionary[sectionName] = metadata.count ? metadata : nil;
            [self didChangeValue];
        }
    }
}

- (NSMutableDictionary *)getMetadataFromSection:(NSString *)sectionName
{
    @synchronized(self) {
        return [self.dictionary[sectionName] mutableCopy];
    }
}

- (id _Nullable)getMetadataFromSection:(NSString *)sectionName
                                        withKey:(NSString *)key
{
    @synchronized(self) {
        return [self.dictionary valueForKeyPath:[NSString stringWithFormat:@"%@.%@", sectionName, key]];
    }
}

- (void)clearMetadataFromSection:(NSString *)sectionName
{
    @synchronized(self) {
        [self.dictionary removeObjectForKey:sectionName];
        [self didChangeValue];
    }
}

- (void)clearMetadataFromSection:(NSString *)section
                         withKey:(NSString *)key
{
    @synchronized(self) {
        [(NSMutableDictionary *)self.dictionary[section] removeObjectForKey:key];
        [self didChangeValue];
    }
}

// MARK: -

- (void)didChangeValue {
    if (self.buffer || self.file) {
        [self serialize];
    }
    if (self.observer) {
        self.observer(self);
    }
}

- (void)setStorageBuffer:(char * _Nullable *)buffer file:(NSString *)file {
    self.buffer = buffer;
    self.file = file;
    [self serialize];
}

- (void)serialize {
    NSError *error = nil;
    NSData *data = BSGJSONDataFromDictionary([self dictionary], &error);
    if (!data) {
        bsg_log_err(@"%s: %@", __FUNCTION__, error);
        return;
    }
    if (self.buffer) {
        [self writeData:data toBuffer:self.buffer];
    }
    if (self.file) {
        [self writeData:data toFile:self.file];
    }
}

//
// Metadata is stored in memory as a JSON encoded C string so that it is accessible at crash time.
//
- (void)writeData:(NSData *)data toBuffer:(char **)buffer {
    char *newbuffer = BSGCStringWithData(data);
    if (!newbuffer) {
        return;
    }
    char *oldbuffer = *buffer;
    *buffer = newbuffer;
    free(oldbuffer);
}

//
// Metadata is also stored on disk so that it is accessible at next launch if an OOM is detected.
//
- (void)writeData:(NSData *)data toFile:(NSString *)file {
    self.pendingWrite = data;
    
    dispatch_async(BSGGetFileSystemQueue(), ^{
        NSData *pendingWrite;
        
        @synchronized (self) {
            if (!self.pendingWrite) {
                // The latest data has already been written to disk.
                return;
            }
            pendingWrite = self.pendingWrite;
        }
        
        NSError *error = nil;
        if (![pendingWrite writeToFile:(NSString *_Nonnull)file options:NSDataWritingAtomic error:&error]) {
            bsg_log_err(@"%s: %@", __FUNCTION__, error);
        }
        
        @synchronized (self) {
            if (self.pendingWrite == pendingWrite) {
                self.pendingWrite = nil;
            }
        }
    });
}

@end
