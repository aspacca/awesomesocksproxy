//
//  SPHAskPassAuthenticator.m
//  An Awesome Socks Proxy Manager
//
//  Created by Andrea Spacca on 18/07/12.
//
//

#import "SPHAskPassAuthenticator.h"
#import "SPHAskSSHPass.h"

@implementation SPHAskPassAuthenticator

-(id)performDefaultImplementation;
{
    NSString *aFifo = [self directParameter];
    NSString *aCaption = [[self evaluatedArguments] objectForKey:@"withCaption"];
    
    SPHAskSSHPass *appDelegate = (SPHAskSSHPass *)[[NSApplication sharedApplication] delegate];
    
    [appDelegate setFifo:aFifo];
    [[appDelegate caption] setStringValue: !aCaption ? @"Insert pass to authenticate" : aCaption ];

    @try {
        [[appDelegate window] center];
        [[appDelegate window] makeKeyAndOrderFront:self];
    }
    @catch (NSException *exception) {
        [[appDelegate window] makeMainWindow];
    }
    @catch (NSException *exception) {
        [[appDelegate window] makeMainWindow];
    }
    @finally {
        
        [[NSApplication sharedApplication] unhide:nil];
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        
        NSRunningApplication* apps = [[NSRunningApplication runningApplicationsWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]] objectAtIndex:0];
        [apps activateWithOptions: NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps];
    }
                                             
    return nil;
}
@end
