//
//  SPHAppDelegate.h
//  Awesome Menubar
//
//  Created by Andrea Spacca on 06/07/12.
//  Copyright (c) 2012 Andrea Spacca. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPHProcessHelper.h"
@interface SPHAppDelegate : NSObject <NSApplicationDelegate, NSAnimationDelegate, NSMenuDelegate, NSWindowDelegate> {
    @private
    BOOL _windowDidResize;
    
    struct timeval _after;
    struct timeval _before;

    NSNumber *_timeSpan;
    NSArray *_networkInterfaces;
    
    __unsafe_unretained NSSegmentedControl *_authChoice;
    __unsafe_unretained NSButton *_saveButton;
    
    NSStatusItem *_statusItem;
    NSMenu *_statusMenu;
    NSMenuItem *_proxyMenuItem;
    NSMenuItem *_ifaceMenuItem;
    
    __unsafe_unretained NSTextField *_userName;
    __unsafe_unretained NSTextField *_serverIp;
    __unsafe_unretained NSTextField *_localPort;
    __unsafe_unretained NSTextField *_remotePort;
    __unsafe_unretained NSTextField *_profileName;
    __unsafe_unretained NSPathControl *_identityPath;
}

@property (nonatomic, strong) NSNumber *timeSpan;

@property (nonatomic, strong) NSArray *networkInterfaces;

@property (strong) NSStatusItem *statusItem;

@property (assign) IBOutlet NSView *authHelp;

@property (strong) IBOutlet NSMenu *statusMenu;
@property (strong) IBOutlet NSMenuItem *proxyMenuItem;
@property (strong) IBOutlet NSMenuItem *ifaceMenuItem;

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSButton *saveButton;
@property (assign) IBOutlet NSSegmentedControl *authChoice;

@property (assign) IBOutlet NSTextField *userName;
@property (assign) IBOutlet NSTextField *serverIp;
@property (assign) IBOutlet NSTextField *localPort;
@property (assign) IBOutlet NSTextField *remotePort;

@property (assign) IBOutlet NSTextField *profileName;

@property (assign) IBOutlet NSPathControl *identityPath;


-(IBAction)addProxy:(id)sender;
-(IBAction)delProxy:(id)sender;

-(IBAction)editProxy:(id)sender;
-(IBAction)saveProxy:(id)sender;


-(IBAction)enableProxy:(id)sender;
-(IBAction)toggleProxy:(id)sender;

-(IBAction)setAuthMethod:(id)sender;
-(IBAction)toggleAuthHelp:(id)sender;

@end
