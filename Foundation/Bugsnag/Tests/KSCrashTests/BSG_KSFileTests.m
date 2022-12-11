//
//  BSG_KSFileTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 13/01/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSG_KSFile.h"

@interface BSG_KSFileTests : XCTestCase

@property NSString *filePath;
@property int fileDescriptor;

@end

@implementation BSG_KSFileTests

- (void)setUp {
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self description]];
    self.fileDescriptor = open(self.filePath.fileSystemRepresentation, O_RDWR | O_CREAT | O_EXCL, 0644);
}

- (void)tearDown {
    close(self.fileDescriptor);
    unlink(self.filePath.fileSystemRepresentation);
}

- (void)testFileWrite {
    BSG_KSFile file;
    const size_t bufferSize = 8;
    char buffer[bufferSize];
    
    BSG_KSFileInit(&file, self.fileDescriptor, buffer, bufferSize);
    XCTAssertEqual(file.bufferSize, bufferSize);
    XCTAssertEqual(file.bufferUsed, 0);
    
    BSG_KSFileWrite(&file, "Someone", 7);
    XCTAssertEqual(file.bufferUsed, 7, @"The buffer should not be flushed until filled");
    BSG_KSFileWrite(&file, " ", 1);
    XCTAssertEqual(file.bufferUsed, 0, @"The buffer should be flushed once filled");
    
    BSG_KSFileWrite(&file, "says", 4);
    BSG_KSFileWrite(&file, ": ", 2);
    XCTAssertEqual(file.bufferUsed, 6, @"The buffer should not be flushed until filled");
    
    BSG_KSFileWrite(&file, "Hello, ", 7);
    XCTAssertEqual(file.bufferUsed, (6 + 7) % bufferSize);
    
    BSG_KSFileWrite(&file, "Supercalifragilisticexpialidocious", 34);
    XCTAssertEqual(file.bufferUsed, 0, @"Large writes should flush the buffer and leave it empty");
    
    BSG_KSFileFlush(&file);
    XCTAssertEqualObjects([self fileContentsAsString], @"Someone says: Hello, Supercalifragilisticexpialidocious");
}

- (NSString *)fileContentsAsString {
    return [NSString stringWithContentsOfFile:self.filePath encoding:NSUTF8StringEncoding error:nil];
}

@end
