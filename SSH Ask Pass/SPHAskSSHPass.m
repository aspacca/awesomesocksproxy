//
//  SSHAskPassApp.m
//  SSHAskPass
//
//  Created by Andrea Spacca on 04/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SPHAskSSHPass.h"

@implementation SPHAskSSHPass
@synthesize window = _window;

@synthesize fifo = _fifo;
@synthesize capt = _capt;
@synthesize caption = _caption;
@synthesize password = _password;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // [self authenticate:@"/tmp/fifo" withCaption:@"From app"];
    
    //  NSLog(@"suite registry: %@", [NSClassFromString(@"NSScriptSuiteRegistry") sharedScriptSuiteRegistry]);
}

- (IBAction)doAuthentication:(id)sender;
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath: self.fifo];
    [fileHandle writeData: [[self.password stringValue] dataUsingEncoding: NSASCIIStringEncoding]];
    [fileHandle closeFile];
    
    self.fifo = nil;
    
    [[NSApplication sharedApplication] terminate:nil];
}
@end