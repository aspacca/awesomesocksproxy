//
//  NSString+SeparatingIntoComponents.h
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

#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>

@interface NSTask (OneLineTasksWithOutput)

+ (NSString *)stringByLaunchingPath:(NSString *)processPath
                      withArguments:(NSArray *)arguments
                       inBackground:(BOOL)inBackground
                              error:(NSError **)error;

+ (NSString *)stringByLaunchingPath:(NSString *)processPath
                      withArguments:(NSArray *)arguments
                     andEnvironment:(NSDictionary *)environment
                       inBackground:(BOOL)inBackground
                              error:(NSError **)error;

@end

#define kNSTaskLaunchFailed -1
#define kNSTaskProcessOutputError -2
