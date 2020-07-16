//
//  libArchive.m
//  Protein
//
//  Created by Lakr Aream on 2020/5/23.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

#import "libArchiveObjc.h"

#define BLOCK_SIZE 16384

NSData* _Nullable libArchiveGetData(NSData* fromData) {
    
    int r;
    struct archive_entry *ae;
    ssize_t size;
    
    struct archive *a = archive_read_new();
    archive_read_support_filter_all(a);
    archive_read_support_format_raw(a);
    r = archive_read_open_memory(a, [fromData bytes], BLOCK_SIZE);
    if (r != ARCHIVE_OK) {
        fprintf(stderr, "[libArchiveExtract] Failed to open file - %s\n", archive_error_string(a));
        return NULL;
    }
    r = archive_read_next_header(a, &ae);
    if (r != ARCHIVE_OK) {
        fprintf(stderr, "[libArchiveExtract] Failed to open file header - %s\n", archive_error_string(a));
        return NULL;
    }
    
    NSMutableData* data = [NSMutableData alloc];
    
    for (;;) {
        void* alloced_buffer = (void*)malloc(BLOCK_SIZE);
        size = archive_read_data(a, alloced_buffer, BLOCK_SIZE);
        if (size < 0) {
            fprintf(stderr, "[libArchiveExtract] File is damaged - %s\n", archive_error_string(a));
            return NULL;
        }
        if (size == 0)
            break;
        [data appendBytes:alloced_buffer length:size];
    }
    
    archive_read_close(a);
    archive_read_free(a);
    
    return data;
    
}

//int libArchiveExtract(NSString* fromArchFile, NSString* writeTo) {
//    
//    if (![[NSFileManager defaultManager] fileExistsAtPath:fromArchFile]) {
//        fprintf(stderr, "[libArchiveExtract] File does not exists");
//        return -1;
//    }
//    if ([[NSFileManager defaultManager] fileExistsAtPath:writeTo]) {
//        fprintf(stderr, "[libArchiveExtract] File exists at target location");
//        return -1;
//    }
//    
//    int r;
//    struct archive_entry *ae;
//    ssize_t size;
//    
//    struct archive *a = archive_read_new();
//    archive_read_support_filter_all(a);
//    archive_read_support_format_raw(a);
//    r = archive_read_open_filename(a, [fromArchFile UTF8String], BLOCK_SIZE);
//    if (r != ARCHIVE_OK) {
//        fprintf(stderr, "[libArchiveExtract] Failed to open file");
//        return -1;
//    }
//    r = archive_read_next_header(a, &ae);
//    if (r != ARCHIVE_OK) {
//        fprintf(stderr, "[libArchiveExtract] Failed to open file header");
//        return -1;
//    }
//    
//    NSMutableData* data = [NSMutableData alloc];
//    
//    for (;;) {
//        void* alloced_buffer = (void*)malloc(BLOCK_SIZE);
//        size = archive_read_data(a, alloced_buffer, BLOCK_SIZE);
//        if (size < 0) {
//            fprintf(stderr, "[libArchiveExtract] File is damaged");
//            return -1;
//        }
//        if (size == 0)
//            break;
//        [data appendBytes:alloced_buffer length:size];
//    }
//    
//    archive_read_close(a);
//    archive_read_free(a);
//    
//    [[NSFileManager defaultManager] createFileAtPath:writeTo contents:data attributes:nil];
//    
//    return 0;
//}
