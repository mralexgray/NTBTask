//
//  NTBTaskTests.m
//
//  Created by Kåre Morstøl on 31/03/14.
//  Copyright (c) 2014 NotTooBad Software. All rights reserved.
//
//  This program and the accompanying materials are made available under the terms of the Eclipse Public License v1.0 which accompanies this
//  distribution, and is available at http://www.eclipse.org/legal/epl-v10.html

#import <XCTest/XCTest.h>
#import "NTBTask.h"
#import "XCTestCase+AsyncTesting.h"

@interface NTBTask_Tests : XCTestCase

@end

@implementation NTBTask_Tests

#if MAC_ONLY
- (void)testWriteInput
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/bin/cat"];
	NSString *input = @"What comes in, must come out";
	[sut write:input];
	NSString *output = [sut waitForOutputString];

	XCTAssertEqualObjects(input, output);
}

- (void)testProcessIdentifier
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/bin/echo"];
	[sut launch];
	[sut waitUntilExit];

	XCTAssert(sut.processIdentifier > 0);
}

- (void)testEnvironment
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/usr/bin/env"];
	sut.environment = @{@"ENVTEST" : @"success"};
	NSString *output = [sut waitForOutputString];

	XCTAssertNotNil(sut.environment);
	XCTAssertEqualObjects(output, @"ENVTEST=success\n");
}

- (void)testWaitForOutputString
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/bin/echo"];

	NSString *output = [sut waitForOutputString];
	XCTAssertNotNil(output);
	XCTAssertEqualObjects(output, @"\n");
}

- (void)testWaitForOutputStringWithArguments
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/bin/echo"];
	sut.arguments = @[ @"testing testing", @"123" ];

	NSString *output = [sut waitForOutputString];
	XCTAssertEqualObjects(output, @"testing testing 123\n");
}

- (void)testCurrentDirectoryPath
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/bin/pwd"];
	sut.currentDirectoryPath = @"/private";

	NSString *output = [sut waitForOutputString];
	XCTAssertEqualObjects(output, @"/private\n");
}

- (void)testAutomaticallyFindsPathForCommand
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"pwd"];
	sut.currentDirectoryPath = @"/private";
	XCTAssertEqualObjects(sut.launchPath, @"/bin/pwd");

	NSString *output = [sut waitForOutputString];
	XCTAssertEqualObjects(output, @"/private\n");
}

- (void)testLeavesLaunchpathAloneIfCommandIsNotFound
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"sltjw6v"];
	XCTAssertEqualObjects(sut.launchPath, @"sltjw6v");
}

- (void)testWwriteAndCloseInputWorksWithLaunch
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/bin/bash"];

	NSMutableString *result = [[NSMutableString alloc] init];
	__block int count = 0;
	sut.outputHandler = ^(NSString *output)
	{
		count++;
		[result appendString:output];
	};
	sut.completionHandler = ^(NTBTask *thistask)
	{
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	};

	NSString *slowscript = @"echo 'sleeping for 0.3'\n"
							"sleep 0.3\n"
							"echo 'sleeping for 0.3'\n"
							"sleep 0.3\n"
							"echo 'sleeping for 0.3'\n"
							"sleep 0.3";
	[sut writeAndCloseInput:slowscript];

	[sut launch];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:5];

	XCTAssertEqualObjects(result, @"sleeping for 0.3\nsleeping for 0.3\nsleeping for 0.3\n", @"incomplete output");
	XCTAssert(count == 3);
	NSTask *_task = (NSTask *)[sut valueForKey:@"_task"];
	XCTAssertNil([_task.standardOutput fileHandleForReading].readabilityHandler, @"should have been set to nil in the completionHandler");
}

- (void)dontTestOutputHandlerCopy
{
	NTBTask *sut = [[NTBTask alloc] initWithLaunchPath:@"/bin/cp"];
	NSString *tempdir = NSTemporaryDirectory();
	NSAssert(tempdir, @"no tempdir");
	sut.arguments = @[ @"-Rpnv", @".", tempdir ];

	NSMutableString *result = [[NSMutableString alloc] init];
	__block int count = 0;

	sut.outputHandler = ^(NSString *output)
	{
		count++;
		[result appendString:output];
	};
	sut.completionHandler = ^(NTBTask *thistask)
	{
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	};

	[sut launch];
	[self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:50];
	NSLog(@"%@\n\n%@", tempdir, result);
	XCTAssert([result length] >= 60, @"incomplete");
	XCTAssert(count > 1);
}
#endif

@end
