//
//  SPHProcesHelper.h
//
//  Created by Matt Gallagher on 4/05/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Excerpts by jongampark on 26/01/2008. 
//  from http://jongampark.wordpress.com/2008/01/26/a-simple-objectie-c-class-for-checking-if-a-specific-process-is-running/
//  Copyright 2008 jongampark. All rights reserved.
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
#import <Cocoa/Cocoa.h> 
#import <SecurityFoundation/SFAuthorization.h>

#ifndef DSProcessesInfo_H
#define DSProcessesInfo_H

extern NSString *DSProcessName;
extern NSString *DSProcessPIDNumber;
extern NSString *DSProcessStartTime;
extern NSString *DSProcessFlags;
extern NSString *DSProcessFlagValue;
extern NSString *DSProcessStatus;
extern NSString *DSProcessStatusValue;
extern NSString *DSProcessSystemPriority;
extern NSString *DSProcessNiceValue;
extern NSString *DSProcessParentPID;
extern NSString *DSProcessOwner;
extern NSString *DSProcessArguments;
extern NSString *DSProcessEnvironment;


void argsNoEnv(pid_t pidNum, NSMutableArray **procArgs);
void args(pid_t pidNum, NSMutableArray **procArgs, NSMutableArray **procEnv);

NSArray *allProcesses __P((void));
NSArray *allProcessesInfo __P((void));

NSDictionary *getProcessInfoByPID __P((int));

NSArray *getProcessInfoByName __P((NSString *));

NSString *nameForProcessWithPID(pid_t pidNum);


NSArray *getProcessArgsByName(NSString *name);
NSDictionary *getProcessArgsByPID(int procPid);
int getProcessPidByFullArgs __P((NSString *, NSString *));

BOOL isProcessRunningByPID __P((int));
BOOL isProcessRunningByName __P((NSString *));
BOOL isProcessRunningByFullArgs __P((NSString *));

#endif