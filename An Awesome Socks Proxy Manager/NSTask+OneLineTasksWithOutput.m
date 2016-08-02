//
//  NSString+SeparatingIntoComponents.m
//
//  Created by Matt Gallagher on 4/05/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Modified by Andrea Spacca on 07/07/12.
//  Copyright (c) 2012 Andrea Spacca. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "NSTask+OneLineTasksWithOutput.h"

@interface SPHTaskOutputReader :NSObject
{
	NSMutableData *standardOutput;
	NSMutableData *standardError;
	BOOL taskComplete;
	BOOL outputClosed;
	BOOL errorClosed;
	NSTask *task;
}

@end

@implementation SPHTaskOutputReader

//
// initWithTask:
//
// Sets the object as an observer for notifications from the task or its
// file handles.
//
// Parameters:
//    aTask - the NSTask object to observe.
//
// returns the initialized output reader
//
- (id)initWithTask:(NSTask *)aTask
{
	self = [super init];
	if (self != nil)
	{
		task = [aTask retain];
		standardOutput = [[NSMutableData alloc] init];
		standardError = [[NSMutableData alloc] init];
		
		NSFileHandle *standardOutputFile = [[aTask standardOutput] fileHandleForReading];
		NSFileHandle *standardErrorFile = [[aTask standardError] fileHandleForReading];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(standardOutNotification:)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:standardOutputFile];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(standardErrorNotification:)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:standardErrorFile];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminatedNotification:)
                                                     name:NSTaskDidTerminateNotification
                                                   object:aTask];
		
		[standardOutputFile waitForDataInBackgroundAndNotify];
		[standardErrorFile waitForDataInBackgroundAndNotify];
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[standardOutput release];
	[standardError release];
	[task release];
	[super dealloc];
}

//
// standardOutputData
//
// Accessor for the data object
//
// returns the object.
//
- (NSData *)standardOutputData
{
	return standardOutput;
}

//
// standardErrorData
//
// Accessor for the data object
//
// returns the object.
//
- (NSData *)standardErrorData
{
	return standardError;
}

//
// standardOutNotification:
//
// Reads standard out into the standardOutput data object.
//
// Parameters:
//    notification - the notification containing the NSFileHandle to read
//
-(void)standardOutNotification: (NSNotification *) notification
{
    NSFileHandle *standardOutFile = (NSFileHandle *)[notification object];
	
	NSData *availableData = [standardOutFile availableData];
	if ([availableData length] == 0)
	{
		outputClosed = YES;
		return;
	}
	
    [standardOutput appendData:availableData];
    [standardOutFile waitForDataInBackgroundAndNotify];
}

//
// standardErrorNotification:
//
// Reads standard error into the standardError data object.
//
// Parameters:
//    notification - the notification containing the NSFileHandle to read
//
-(void)standardErrorNotification: (NSNotification *) notification
{
    NSFileHandle *standardErrorFile = (NSFileHandle *)[notification object];
    
	NSData *availableData = [standardErrorFile availableData];
	if ([availableData length] == 0)
	{
		errorClosed = YES;
		return;
	}
	
    [standardError appendData:availableData];
    [standardErrorFile waitForDataInBackgroundAndNotify];
}

//
// terminatedNotification:
//
// Sets the taskComplete flag when a terminated notification is received.
//
// Parameters:
//    notification - the notification
//
- (void)terminatedNotification: (NSNotification *)notification
{
    taskComplete = YES;
}

//
// launchTaskAndRunSynchronous
//
// Runs the current event loop until the terminated notification is received
//
- (void)launchTaskInBackground
{
	[task launch];
}

//
// launchTaskAndRunSynchronous
//
// Runs the current event loop until the terminated notification is received
//
- (void)launchTaskAndRunWaiting
{
	[task launch];
    [task waitUntilExit];
}

- (void)launchTaskAndRunSynchronous
{
	[task launch];
	
	BOOL isRunning = YES;
	while (isRunning && (!taskComplete || !outputClosed || !errorClosed))
	{
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                             beforeDate:[NSDate distantFuture]];
	}
}

//
// launchTaskAndRunSynchronous
//
// Runs the current event loop until the terminated notification is received
//
- (void)launchTaskAndRunAsynchronousForObject:(id)receiver selector:(SEL)selector
{
	[task launch];
	
	BOOL isRunning = YES;
	while (isRunning && (!taskComplete || !outputClosed || !errorClosed))
	{
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                             beforeDate:[NSDate distantFuture]];
	}
}

@end

@implementation NSTask (OneLineTasksWithOutput)

//
// stringByLaunchingPath:withArguments:error:
//
// Executes a process and returns the standard output as an NSString
//
// Parameters:
//    processPath - the path to the executable
//    arguments - arguments to pass to the executable
//    error - an NSError pointer or nil
//
// Returns the standard out from the process an an NSString (if the NSTask
//	completes successfully), nil otherwise.
// 
// Error handling notes:
//
// If the NSTask throws an exception, it will be automatically caught and
// the "error" object will have the code kNSTaskLaunchFailed and the
// localizedDescription will be the -[NSException reason] from the thrown
// exception. The return value will be nil in this case.
//
// If the NSTask is successfully run but outputs on standard error, the
// localizedDescription of the NSError will be set to the string output to
// standard error (the output on standard out will still be returned as a
// string). The error code will be kNSTaskProcessOutputError in this case.
//
+ (NSString *)stringByLaunchingPath:(NSString *)processPath
                      withArguments:(NSArray *)arguments
                      andEnvironment:(NSDictionary *)environment
                       inBackground:(BOOL)inBackground
                              error:(NSError **)error
{
	NSTask *task = [[[NSTask alloc] init] autorelease];
	
	[task setLaunchPath:processPath];
	[task setArguments:arguments];
    [task setEnvironment:environment];
    
	NSString *outputString = nil;
	NSString *errorString = nil;
    SPHTaskOutputReader *outputReader;
    
	@try
	{
        
        if (inBackground) {
            [task setStandardOutput:[NSPipe pipe]];
            [task setStandardError:[NSPipe pipe]];
            
            outputReader = [[SPHTaskOutputReader alloc] initWithTask:task];
            
            [outputReader launchTaskInBackground];
        } else {
            [task launch];
            [task waitUntilExit];
            
            /*
            
            outputString = [[[NSString alloc] initWithData:[outputReader standardOutputData]
                                                  encoding:NSUTF8StringEncoding]
                            autorelease];
            
            
            errorString = [[[NSString alloc] initWithData:[outputReader standardErrorData]
                                                 encoding:NSUTF8StringEncoding]
                           autorelease];
             
             
             */
        }
	}
	@catch (NSException *exception)
	{
		*error = [NSError errorWithDomain:@"com.apple.NSTask.OneLineTasksWithOutput"
                                     code:kNSTaskLaunchFailed
                                 userInfo: [NSDictionary dictionaryWithObject:[exception reason]
                                                                       forKey:NSLocalizedDescriptionKey]];
        
        
		return nil;
	}
	@finally
	{
        if (inBackground) {
            [outputReader release];
        }
	}
    
	if (inBackground && error)
	{
		if ([errorString length] > 0)
		{
			*error = [NSError errorWithDomain:@"com.apple.NSTask.OneLineTasksWithOutput"
                                         code:kNSTaskProcessOutputError
                                     userInfo: [NSDictionary dictionaryWithObject:errorString
                                                                           forKey:@"standardError"]];
		}
		else
		{
			*error = nil;
		}
	}
    
	return outputString;
    
}

+ (NSString *)stringByLaunchingPath:(NSString *)processPath
                      withArguments:(NSArray *)arguments
                       inBackground:(BOOL)inBackground
                              error:(NSError **)error
{
	NSTask *task = [[[NSTask alloc] init] autorelease];
	
	[task setLaunchPath:processPath];
	[task setArguments:arguments];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:[NSPipe pipe]];
    
	SPHTaskOutputReader *outputReader = [[SPHTaskOutputReader alloc] initWithTask:task];
    
	NSString *outputString = nil;
	NSString *errorString = nil;
	@try
	{
        
        if (inBackground) {
            [outputReader launchTaskInBackground];
        } else {
            [outputReader launchTaskAndRunSynchronous];
            
            outputString = [[[NSString alloc] initWithData:[outputReader standardOutputData]
                                                  encoding:NSUTF8StringEncoding]
                            autorelease];
            
            
            errorString = [[[NSString alloc] initWithData:[outputReader standardErrorData]
                                                 encoding:NSUTF8StringEncoding]
                           autorelease];
        }
	}
	@catch (NSException *exception)
	{
		*error = [NSError errorWithDomain:@"com.apple.NSTask.OneLineTasksWithOutput"
                                     code:kNSTaskLaunchFailed
                                 userInfo: [NSDictionary dictionaryWithObject:[exception reason]
                                                                       forKey:NSLocalizedDescriptionKey]];
        
        
		return nil;
	}
	@finally
	{
		[outputReader release];
	}
	
	if (error)
	{
		if ([errorString length] > 0)
		{
			*error = [NSError errorWithDomain:@"com.apple.NSTask.OneLineTasksWithOutput"
                                         code:kNSTaskProcessOutputError
                                     userInfo: [NSDictionary dictionaryWithObject:errorString
                                                                           forKey:@"standardError"]];
		}
		else
		{
			*error = nil;
		}
	}

	return outputString;
}
@end
