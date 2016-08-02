//
//  SPHAppDelegate.m
//  Awesome Menubar
//
//  Created by Andrea Spacca on 06/07/12.
//  Copyright (c) 2012 Andrea Spacca. All rights reserved.
//

#import "SPHAppDelegate.h"
#import <sys/time.h>
#import <CoreData/CoreData.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "NSTask+OneLineTasksWithOutput.h"
#import "NSUserDefaults+NonPropertyValue.h"

@implementation SPHAppDelegate

@synthesize window = _window;

@synthesize timeSpan = _timeSpan;
@synthesize networkInterfaces = _networkInterfaces;

@synthesize authChoice = _authChoice;
@synthesize saveButton = _saveButton;

@synthesize statusItem = _statusItem;
@synthesize statusMenu = _statusMenu;
@synthesize proxyMenuItem = _proxyMenuItem;
@synthesize ifaceMenuItem = _ifaceMenuItem;

@synthesize userName = _userName;
@synthesize serverIp = _serverIp;
@synthesize localPort = _localPort;
@synthesize remotePort = _remotePort;
@synthesize profileName = _profileName;
@synthesize identityPath = _identityPath;


#pragma mark -- Init
#pragma mark -- Constant
NSString *const kSPHProxyList = @"kSPHProxyList";
NSString *const kSPHProxyIndex = @"kSPHProxyIndex";

NSString *const kSPHUserName = @"kSPHUserName";
NSString *const kSPHServerIp = @"kSPHServerIp";
NSString *const kSPHLocalPort = @"kSPHLocalPort";
NSString *const kSPHRemotePort = @"kSPHRemotePort";
NSString *const kSPHProfileName = @"kSPHProfileName";

NSString *const kSPHAuthType = @"kSPHAuthType";
NSString *const kSPHAuthPass = @"kSPHAuthPass";
NSString *const kSPHAuthIdentity = @"kSPHAuthIdentity";
NSString *const kSPHAuthIdentityPath = @"kSPHAuthIdentityPath";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

-(void)awakeFromNib;
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *iconFile = [bundle URLForResource:@"walkingsocks" withExtension:@"png" subdirectory:@"Images"];
    
    NSImage *statusIcon = [[NSImage alloc] initWithContentsOfURL:iconFile];
    
    _windowDidResize = NO;
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    [self.statusItem setImage:statusIcon];
    [self.statusItem setAlternateImage:statusIcon];
    
    [self.statusItem setMenu:self.statusMenu];

    [self.statusItem setToolTip:@"Eat My Socks!"];
    [self.statusItem setHighlightMode:YES];
    
    self.networkInterfaces = nil;
    [self.statusMenu update];
}

#pragma mark -- UI
-(IBAction)toggleAuthHelp:(id)sender;
{
    // Create the view animation object.
    NSAnimation *authHelpFading = [[NSAnimation alloc] initWithDuration:0. animationCurve:NSAnimationLinear];
    
    [authHelpFading setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [authHelpFading setDelegate:self];

    
    _windowDidResize = NO;

    CGRect winFrame = CGRectMake(self.window.frame.origin.x,
                                 self.window.frame.origin.y,
                                 self.window.frame.size.width,
                                 self.window.frame.size.height > 233. ? 233. : 363.);
    
    
    
    // Will resize to smaller, hide and start animation now
    if (winFrame.size.height < 363.) {
        [self.authHelp setHidden:YES];
        [authHelpFading startAnimation];
    }
    
    [self.window setFrame:winFrame display:YES animate:YES];
    

    // Will resize to bigger, start animation now
    if (winFrame.size.height > 233.) {
        [authHelpFading startAnimation];
    }
}

- (void) resetFormWindow;
{
    self.saveButton.tag = 0;
    self.authChoice.tag = 0;
    
    // [self toggleAuthHelp:nil];
    
    self.authChoice.selectedSegment = 0;
    
    self.identityPath.URL = nil;
    
    self.userName.stringValue = @"";
    self.serverIp.stringValue = @"";
    self.localPort.stringValue = @"";
    self.remotePort.stringValue = @"";
    
    self.profileName.stringValue = @"";
}

#pragma mark -- NSAnimation delegate
- (BOOL)animationShouldStart:(NSAnimation*)animation;
{
    if (!_windowDidResize) {
        // Has to resize to smaller, already hidden, run start animation
        if (self.window.frame.size.height > 233.) {
            return YES;
        }
    }

    // Did resize to bigger, then show and run start animation
    if (self.window.frame.size.height > 233.) {
        [self.authHelp.animator setHidden:NO];
        return YES;
    }
    
    
    return NO;
}

#pragma mark -- NSMenu delegate
- (void) menuNeedsUpdate:(NSMenu *)menu;
{
    gettimeofday(&_before , NULL);

    NSMutableSet *proxyList = [SPHStandardUserDefaults() nonPropertyObjectForKey:kSPHProxyList];
    
    if (!proxyList) {
        proxyList = [NSMutableSet set];
        [SPHStandardUserDefaults() setNonPropertyObject:proxyList forKey:kSPHProxyList];
        [SPHStandardUserDefaults() synchronize];
    }
    
    NSSortDescriptor *sortingDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSPHProfileName ascending:NO];
    NSArray *sortedProxyList = [proxyList sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortingDescriptor]];

    [sortedProxyList enumerateObjectsUsingBlock:^(NSDictionary *proxyData, NSUInteger idx, BOOL *stop) {
        
        NSMenuItem *aProxyMenuItem = [self.proxyMenuItem copy];
        
        NSString *proxyIndex_ = [proxyData valueForKey:kSPHProxyIndex];
        NSString *profileName_ = [proxyData valueForKey:kSPHProfileName];
        
        NSInteger baseTag = [proxyIndex_ integerValue];
        
        NSInteger managementTag = baseTag * 10;
        NSInteger switchToggleTag = 1000;
        
        aProxyMenuItem.tag = baseTag;
        aProxyMenuItem.title = profileName_;
        
        [aProxyMenuItem.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem *managementMenuItem, NSUInteger idx, BOOL *stop) {
            /*
            if (![managementMenuItem isEnabled]) {
                return;
            }
            */
            
            managementMenuItem.tag = abs(managementMenuItem.tag) + managementTag;
            
            if (4 == (managementMenuItem.tag % managementTag)) {
                NSDictionary *proxyData = [self proxyDataFromIndex:aProxyMenuItem.tag];
                managementMenuItem.state = [self hasMacthingConncetionsForProxyData:proxyData] ? 1 : 0;
            }

            [managementMenuItem.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem *switchToggleMenuItem, NSUInteger idx, BOOL *stop) {
                if (100100 < switchToggleMenuItem.tag) {
                    [managementMenuItem.submenu removeItem:switchToggleMenuItem];
                    
                    return;
                    
                }

            }];
            
            if (5 != (managementMenuItem.tag % managementTag)) {
                return;
            }
            
            [self.networkInterfaces enumerateObjectsUsingBlock:^(NSDictionary *ifaceData, NSUInteger idx, BOOL *stop) {
                // PUSH TO 2 -> idx * 100 = 200: skip reserved 000 and 100 position
                NSMenuItem *anIfaceMenuItem = [self.ifaceMenuItem copy];
                
                anIfaceMenuItem.title = [ifaceData valueForKey:(__bridge NSString*) kSCPropUserDefinedName];
                anIfaceMenuItem.tag = managementTag + switchToggleTag * ++idx; // INCREMENT TO AVOID per zero PRODUCT
                
                anIfaceMenuItem.state = [self getStatusOnNetworkDevice:ifaceData forProxy:proxyData] ? 1 : 0;

                anIfaceMenuItem.hidden = NO;
                [managementMenuItem.submenu insertItem:anIfaceMenuItem atIndex:2];
                
            }];
            
            if ([self.networkInterfaces lastObject]) {
                managementMenuItem.enabled = YES;
            }
        }];
        
        aProxyMenuItem.enabled = YES;
        
        NSMenuItem *existingItem = [menu itemWithTag:aProxyMenuItem.tag];
        
        if (existingItem) {
            [menu removeItem:existingItem];
        }
        
        [aProxyMenuItem setHidden:NO];
        [menu insertItem:aProxyMenuItem atIndex:2];
        
    }];

    if (0 < [proxyList count]) {
        [self.proxyMenuItem setHidden:YES];
    } else {
        [self.proxyMenuItem setHidden:NO];
    }
}

#pragma mark -- NSWindowDelegate delegate
- (void)windowDidResize:(NSNotification *)notification;
{
    _windowDidResize = YES;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    _windowDidResize = NO;
    
    return frameSize;
}

#pragma mark -- Accessors
-(NSNumber *)timeSpan;
{
    gettimeofday(&_after , NULL);
    
    double timediff = (_after.tv_sec - _before.tv_sec) + 1e-6 * (_after.tv_usec - _before.tv_usec); /* in seconds */

    // NSLog(@"time: %f", timediff);
    
    gettimeofday(&_before , NULL);
    
    return [NSNumber numberWithDouble:timediff];
}

// @see http://stackoverflow.com/questions/6795798/how-to-determine-netmask-of-active-interface-in-objective-c-on-a-mac
-(NSArray *)networkInterfaces;
{
    if (_networkInterfaces) {
        return _networkInterfaces;
    }
    
	__block NSMutableArray *networkInterface = [NSMutableArray array];
    
    SCPreferencesRef preferences = SCPreferencesCreate(NULL, CFSTR("org.spacca.aWSPM"), NULL);
    
    if (!preferences) {
        return nil;
    }

    
    SCDynamicStoreRef storeRef = SCDynamicStoreCreate(NULL, CFSTR("org.spacca.aWSPM"), NULL, NULL);
    CFPropertyListRef services = SCDynamicStoreCopyValue(storeRef, CFSTR("Setup:/Network/Global/IPv4"));
    NSArray  *serviceOrder = (NSArray  *)[(__bridge_transfer NSDictionary  *)services valueForKey:@"ServiceOrder"];
    
    // NSString *servicePath = @"Setup:/Network/Service";
    
    [serviceOrder enumerateObjectsUsingBlock:^(NSString *serviceID, NSUInteger idx, BOOL *stop) {
        
        SCNetworkServiceRef networkService = SCNetworkServiceCopy(preferences, (__bridge CFStringRef)serviceID);
        
        
        NSString *userDefinedName = (__bridge NSString *) SCNetworkServiceGetName(networkService);
        
        SCNetworkProtocolRef networkProtocol = SCNetworkServiceCopyProtocol(networkService, kSCNetworkProtocolTypeProxies);
        if (!networkProtocol) {
            return;
        }
        
        
        NSDictionary *proxies = (__bridge NSDictionary *) SCNetworkProtocolGetConfiguration(networkProtocol);
        NSString *socksPort = [NSString stringWithFormat:@"%@", [proxies valueForKey:(__bridge NSString*) kSCPropNetProxiesSOCKSPort]];
        NSString *socksEnable = [NSString stringWithFormat:@"%@", [proxies valueForKey:(__bridge NSString*) kSCPropNetProxiesSOCKSEnable]];
        
        if (networkProtocol) {
            CFRelease(networkProtocol);
        }
        
        /*
         if (networkService) {
         CFBridgingRelease(networkService);
         }
         */

        if (!userDefinedName) {
            return ;
        }

        NSDictionary *ifaceData = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:serviceID, 
                                                                       userDefinedName, 
                                                                       socksPort, 
                                                                       socksEnable, nil]
                                   
                                                              forKeys:[NSArray arrayWithObjects:@"ServiceID", 
                                                                       (__bridge_transfer  NSString*) kSCPropUserDefinedName, 
                                                                       (__bridge_transfer NSString*) kSCPropNetProxiesSOCKSPort, 
                                                                       (__bridge_transfer NSString*) kSCPropNetProxiesSOCKSEnable, nil]];
        
        [networkInterface addObject:ifaceData];
    }];
    
    if (services) {
        // CFRelease(services);
    }
    
    
    if (storeRef) {
        // CFRelease(storeRef);
    }
    
    
    NSSortDescriptor *sortingDescriptor = [NSSortDescriptor sortDescriptorWithKey:(__bridge_transfer NSString*) kSCPropUserDefinedName ascending:NO];
    _networkInterfaces = [[networkInterface copy] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortingDescriptor]];
    
    return _networkInterfaces;
}

#pragma mark -- Helpers
-(NSInteger)ifaceIndexFromTag:(NSInteger)tag;
{
    if (1000 > tag) {
        return -1;
    }
    
    NSInteger ifaceIndex = ((tag - (tag % 1000)) / 1000);

    if (0 > tag) {
        return -1;
    }

    
    return --ifaceIndex; // DECREASE TO REBASE SKIPPED per zero
}

-(NSInteger)proxyIndexFromTag:(NSInteger)tag;
{
    if (10 > tag) {
        return -1;
    }
    
    NSInteger proxyIndex = (tag - (1000 * abs((int)tag / 1000)) - (tag % 10)) / 10;;
    
    return proxyIndex;
}


-(NSDictionary *)proxyDataFromIndex:(NSInteger)proxyIndex;
{
    NSMutableSet *proxyList = [SPHStandardUserDefaults() nonPropertyObjectForKey:kSPHProxyList];

    NSSet *originalProxy = [proxyList objectsPassingTest:^BOOL(NSDictionary *obj, BOOL *stop) {
    if ([[obj valueForKey:kSPHProxyIndex] integerValue] == proxyIndex) {
        *stop = YES;
        
        return YES;
    }
        
        return NO;
    }];


    // Something wrong
    if (1 != [originalProxy count]) {
        return nil;
    }

    return [originalProxy anyObject];
}


-(NSDictionary *)bareInfoFromProxyData:(NSDictionary *)proxyData;
{    
    NSString *serverIp_ = [proxyData objectForKey:kSPHServerIp];
    NSString *localPort_ = [proxyData objectForKey:kSPHLocalPort];
    NSString *remotePort_ = [proxyData objectForKey:kSPHRemotePort];
    
    NSArray *values = [NSArray arrayWithObjects:serverIp_, localPort_, remotePort_, nil];
    NSArray *keys = [NSArray arrayWithObjects:kSPHProfileName, kSPHLocalPort, kSPHRemotePort, nil];
    
    return [NSDictionary dictionaryWithObjects:values forKeys:keys];
}

-(NSDictionary *)proxyDictionaryWithName:(NSString *)profileName_
                                userName:(NSString *)userName_
                                serverIp:(NSString *)serverIp_
                              remotePort:(NSString *)remotePort_
                               localPort:(NSString *)localPort_
                             andAuthInfo:(NSDictionary *)authInfo;

{
    
    NSString *authType_;
    id authIdentityPath_ = [authInfo objectForKey:kSPHAuthIdentityPath];
    
    if (1 == [(NSSegmentedControl *)[authInfo objectForKey:kSPHAuthType] selectedSegment]) {
        authType_ = kSPHAuthIdentity;
        
        if (![[authIdentityPath_ path] length]) {
            authIdentityPath_ = [NSNull null];
        }
        
    } else {
        
        authType_ = kSPHAuthPass;
    }
    
    
    NSArray *values = [NSArray arrayWithObjects:profileName_, userName_, serverIp_, localPort_, remotePort_, authType_, authIdentityPath_,  nil];
    NSArray *keys = [NSArray arrayWithObjects:kSPHProfileName, kSPHUserName, kSPHServerIp, kSPHLocalPort, kSPHRemotePort, kSPHAuthType, kSPHAuthIdentityPath, nil];
    
    NSDictionary *proxyData = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    return proxyData;
}

#pragma mark -- Dynamic Store helpers
// @see http://00f.net/2011/08/14/programmatically-changing-network-configuration-on-osx/
- (BOOL) touchDynamicStore;
{
    SCDynamicStoreRef touch = SCDynamicStoreCreate(NULL, CFSTR("org.spacca.aWSPM"), NULL, NULL);

    if (touch) {
        CFRelease(touch);
    }
    
    NSLog(@"DynamicStore updated");
    
    return TRUE;
}

- (BOOL) proxySupportForNetworkService: (SCNetworkServiceRef)networkService
{
    SCNetworkInterfaceRef interface = SCNetworkServiceGetInterface(networkService);
    if (!interface) {
        return NO;
    }
    
    NSArray *supportedProtocols = (__bridge_transfer NSArray *) SCNetworkInterfaceGetSupportedProtocolTypes(interface);
    if ([supportedProtocols indexOfObject: (__bridge NSString *) kSCNetworkProtocolTypeProxies] == NSNotFound) {
        if (interface) {
            CFRelease(interface);
        }
        
        return NO;
    }
    
    SCNetworkProtocolRef networkProtocol = SCNetworkServiceCopyProtocol(networkService, kSCNetworkProtocolTypeProxies);
    
    BOOL ret = SCNetworkProtocolGetEnabled(networkProtocol);
    
    if (networkProtocol) {
        CFRelease(networkProtocol);
    }
    
    /*
     if (interface) {
     CFRelease(interface);
     }
     */
    
    return ret;
}

- (BOOL)setProxyData:(NSDictionary *)proxyData forNetworkService:(SCNetworkServiceRef)networkService;
{
    NSNumber *localPort_ = [NSNumber numberWithInt:[[proxyData valueForKey:kSPHLocalPort] intValue]];
    
    if (!localPort_ || 1 > [localPort_ intValue]) {
        return NO;
    }

    if ([self proxySupportForNetworkService: networkService] == NO) {
        return NO;
    }
    
    SCNetworkProtocolRef networkProtocol = SCNetworkServiceCopyProtocol(networkService, kSCNetworkProtocolTypeProxies);
    
    if (!networkProtocol) {
        return NO;
    }

    
    NSMutableDictionary *proxyDict = [(__bridge NSDictionary *) SCNetworkProtocolGetConfiguration(networkProtocol) mutableCopy];
    
    NSNumber *enableFlag = [proxyDict valueForKey:(__bridge NSString*) kSCPropNetProxiesSOCKSEnable];

    if (proxyDict) {
        NSLog(@"This interface had an existing configuration");

        NSNumber *currentPort = [proxyDict valueForKey:(__bridge NSString*) kSCPropNetProxiesSOCKSPort];
        
        if (![currentPort intValue] == [localPort_ intValue]) { // We are switching proxy, force enabled
            
            enableFlag = [NSNumber numberWithInt:1];
            
        } else {
            
            enableFlag = ![enableFlag intValue] ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0];  // We are on the same proxy, toggle flag
            
        }
        
        SCNetworkProtocolSetConfiguration(networkProtocol, NULL);
    } else {
        NSLog(@"This interface had no existing configuration");
        
        enableFlag = [NSNumber numberWithInt:1];
        
        proxyDict = [NSMutableDictionary dictionary];
    }
    
    
    
    [proxyDict setValue:localPort_ forKey:(__bridge NSString*) kSCPropNetProxiesSOCKSPort];
    [proxyDict setValue:enableFlag forKey:(__bridge NSString*) kSCPropNetProxiesSOCKSEnable];
    [proxyDict setValue:@"localhost" forKey:(__bridge NSString*) kSCPropNetProxiesSOCKSProxy];
    
    BOOL ret = SCNetworkProtocolSetConfiguration(networkProtocol, (__bridge CFDictionaryRef) proxyDict);
    
    /*
     if (networkProtocol) {
     CFRelease(networkProtocol);
     }
     */
    
    return ret;
}

-(BOOL)applyProxyForServiceID:(NSString *)serviceID withBlock:(BOOL (^)(SCNetworkServiceRef networkService))applyBlock andCommit:(BOOL)commit;
{
    
    // @see http://michaelobrien.info/blog/2009/07/authorizationexecutewithprivileges-a-simple-example/
    // Create authorization reference
    OSStatus status;
    AuthorizationRef authorizationRef;
    

    // kAuthorizationRightExecute == "system.privilege.admin"
    AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &right};
    
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;

    // AuthorizationCreate and pass NULL as the initial
    // AuthorizationRights set so that the AuthorizationRef gets created
    // successfully, and then later call AuthorizationCopyRights to
    // determine or extend the allowable rights.
    // http://developer.apple.com/qa/qa2001/qa1172.html
    
    status = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authorizationRef);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Error Creating Initial Authorization: %d", status);
        
        return NO;
    }
    

    /*
    // Call AuthorizationCopyRights to determine or extend the allowable rights.
    status = AuthorizationCopyRights(authorizationRef, &rights, NULL, flags, NULL);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Copy Rights Unsuccessful: %d", status);
        
        return NO;
    }
     */
    
    
    SCPreferencesRef preferences = SCPreferencesCreateWithAuthorization(NULL, CFSTR("org.spacca.aWSPM"), NULL, authorizationRef);
    SCPreferencesLock(preferences, TRUE);
    
    SCNetworkServiceRef networkService = SCNetworkServiceCopy(preferences, CFBridgingRetain(serviceID));
    
    BOOL ret = applyBlock(networkService);
    
    SCPreferencesUnlock(preferences);
    
    if (commit) {
        SCPreferencesCommitChanges(preferences);
        SCPreferencesApplyChanges(preferences);
    }
    
    if (preferences) {
        // CFRelease(preferences);
    }
    
    if (networkService) {
        // CFRelease(networkService);
    }
    
    if (commit) {
        [self touchDynamicStore];
    }
    
    // The only way to guarantee that a credential acquired when you
    // request a right is not shared with other authorization instances is
    // to destroy the credential.  To do so, call the AuthorizationFree
    // function with the flag kAuthorizationFlagDestroyRights.
    // http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/02authconcepts/chapter_2_section_7.html
    AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
    
    return ret;
}

#pragma mark -- Connection helpers
-(NSInteger)firstMacthingPidForProxyData:(NSDictionary *)proxyData;
{
    // lsof -Fn -nP -w -a -cssh -i@198.144.190.126:7631 -i@localhost:19321
    NSString *serverIp_ = [proxyData valueForKey:kSPHServerIp];
    NSString *localPort_ = [proxyData valueForKey:kSPHLocalPort];
    NSString *remotePort_ = [proxyData valueForKey:kSPHRemotePort];
    
    NSString *localConnection = [NSString stringWithFormat:@"-i:%@", localPort_];
    NSString *remoteConnection = [NSString stringWithFormat:@"-i@%@:%@", serverIp_, remotePort_];
    
    NSError *error;
    NSString *matchingConnections = [NSTask stringByLaunchingPath:@"/usr/sbin/lsof"
                                                   withArguments:[NSArray arrayWithObjects:@"-Fpn", @"-nP", @"-w", @"-a", @"-cssh", localConnection, remoteConnection, nil]
                                                    inBackground:NO
                                                           error:&error];
    
    
    
    NSArray *toBeParsed = [matchingConnections componentsSeparatedByString:@"\n"];
    
    __block NSString *matchedPid;
    __block NSInteger totConnections = 0;
    
    
    [toBeParsed enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        if (1 > [obj length]) {
            return;
        }

        if ([[obj substringToIndex:1] isEqualToString:@"p"]) {
            
            totConnections = 0;
            matchedPid = [obj substringFromIndex:1];
            
        } else {
            
            ++totConnections;
            
        }

        if (1 < totConnections) {
            *stop = YES;
        }
        
    }];
    
    return 1 < totConnections ? [matchedPid intValue] : -1;
}

-(BOOL)getStatusOnNetworkDevice:(NSDictionary *)interfaceData forProxy:(NSDictionary *)proxyData;
{
    NSString *localPort_ = [proxyData objectForKey:kSPHLocalPort];
    
    BOOL isAProxyEnabled = [[interfaceData valueForKey:(__bridge NSString*) kSCPropNetProxiesSOCKSEnable] isEqualToString:@"1"];
    BOOL isCurrentProxyPort = [[interfaceData valueForKey:(__bridge NSString*) kSCPropNetProxiesSOCKSPort] isEqualToString:localPort_];
    
    return isAProxyEnabled && isCurrentProxyPort;
}

-(BOOL)hasMacthingConncetionsForProxyData:(NSDictionary *)proxyData;
{
    // netstat -alnv -p TCP | grep -E '19321.+LISTEN|198.144.190.126.7631'
    NSString *serverIp_ = [proxyData valueForKey:kSPHServerIp];
    NSString *localPort_ = [proxyData valueForKey:kSPHLocalPort];
    NSString *remotePort_ = [proxyData valueForKey:kSPHRemotePort];
    
    serverIp_ = [serverIp_ stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    
    NSError *error;
    NSArray *currentConnctions = [[NSTask stringByLaunchingPath:@"/usr/sbin/netstat"
                                                    withArguments:[NSArray arrayWithObjects:@"-alnv", @"-pTCP", nil]
                                                     inBackground:NO
                                                            error:&error] componentsSeparatedByString:@"\n"];
    
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\.%@.+LISTEN|%@\\.%@.+(ESTABLISHED|CLOSE_WAIT)", localPort_, serverIp_, remotePort_]
                                                                           options:(NSRegularExpressionCaseInsensitive |
                                                                                    NSRegularExpressionAllowCommentsAndWhitespace |
                                                                                    NSRegularExpressionDotMatchesLineSeparators |
                                                                                    NSRegularExpressionAnchorsMatchLines)
                                                                             error:nil];
    
    __block NSInteger totMatches = 0;
    [currentConnctions enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        if (1 < totMatches) {
            *stop = YES;
            
            return;
        }
        
        BOOL check = [regex numberOfMatchesInString:obj
                                            options:0
                                              range:NSMakeRange(0, [obj length])];
        
        if (check) {
            ++totMatches;
        }
    }];
    
    return 1 < totMatches;
    
    // int aPid = (int)[self firstMacthingPidForProxyData:proxyData];
    // return 0 < aPid;
}

#pragma mark -- IBAction - Auth method
-(IBAction)setAuthMethod:(id)sender;
{
    self.identityPath.URL = nil;
    NSSegmentedControl *segmentedControl = (NSSegmentedControl *)sender;
    
    if (1 == segmentedControl.selectedSegment) {
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        
        // Configure your panel the way you want it
        [panel setCanChooseFiles:YES];
        [panel setCanChooseDirectories:NO];
        [panel setAllowsMultipleSelection:NO];
        
        [panel beginSheetModalForWindow:self.window  completionHandler:^(NSInteger result){
            [panel orderOut:nil];

            if (result == NSFileHandlingPanelOKButton) {
                for (NSURL *fileURL in [panel URLs]) {
                    
                    if (![[fileURL path] length]) {
                        
                        self.identityPath.URL = nil;
                        
                    } else {
                        
                        self.identityPath.URL = fileURL;
                    }
                }
            }
        }];    
    }
}

#pragma mark -- IBAction - Proxy CRUD
-(IBAction)addProxy:(id)sender;
{
    [self resetFormWindow];
    
    if (![self.window isKeyWindow]) {
        [self.window makeKeyAndOrderFront:self];
    }
    
    [self.window makeMainWindow];
    
    [[NSApplication sharedApplication] unhide:self.window];
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

-(IBAction)delProxy:(id)sender;
{
    [self resetFormWindow];
    
    [[NSApplication sharedApplication] hide:self.window];
    
    NSInteger proxyIndex = [self proxyIndexFromTag: [sender tag]];
    
    
    // Safety check
    if (1 > proxyIndex) {
        // TODO: Alert
        
        return;
    }
    
    NSMutableSet *proxyList = [SPHStandardUserDefaults() nonPropertyObjectForKey:kSPHProxyList];
    
    // Get existing
    NSDictionary *proxyData = [self proxyDataFromIndex:proxyIndex];
    if (!proxyData) {
        // TODO: Alert
        
        return;
    }
    
    int pid = (int)[self firstMacthingPidForProxyData:proxyData];;
    if (0 < pid) {
        kill(pid, SIGTERM);
    }
    
    // ... and purge
    [proxyList minusSet:[NSSet setWithObject:proxyData]];
    
    
    [SPHStandardUserDefaults() setNonPropertyObject:proxyList forKey:kSPHProxyList];
    [SPHStandardUserDefaults() synchronize];

    
    NSMenuItem *removingItem = [self.statusMenu itemWithTag:proxyIndex];
    [self.statusMenu removeItem:removingItem];

    self.networkInterfaces = nil;
    [self.statusMenu update];
}

-(IBAction)editProxy:(id)sender;
{
    NSInteger proxyIndex = [self proxyIndexFromTag: [sender tag]];
    // Safety check
    if (1 > proxyIndex) {
        [self resetFormWindow];
        
        [[NSApplication sharedApplication] hide:self.window];
        
        
        // TODO: Alert
        
        return;
    }
    
    // Get existing
    NSDictionary *proxyData = [self proxyDataFromIndex:proxyIndex];
    if (!proxyData) {
        [self resetFormWindow];
        
        [[NSApplication sharedApplication] hide:self.window];
        
        
        // TODO: Alert
        
        return;
    }
    
    
    self.saveButton.tag = [sender tag];
    self.authChoice.tag = [sender tag];
    
    self.userName.stringValue = [proxyData valueForKey:kSPHUserName];
    self.serverIp.stringValue = [proxyData valueForKey:kSPHServerIp];
    self.localPort.stringValue = [proxyData valueForKey:kSPHLocalPort];
    self.remotePort.stringValue = [proxyData valueForKey:kSPHRemotePort];
    self.profileName.stringValue = [proxyData valueForKey:kSPHProfileName];
    
    self.authChoice.selectedSegment = [[proxyData valueForKey:kSPHAuthType] isEqualToString:kSPHAuthPass] ? 0 : 1;
    
    if ([[proxyData valueForKey:kSPHAuthIdentityPath] isKindOfClass:NSClassFromString(@"NSNull")]) {
        
        self.identityPath.URL = nil;
        
    } else {
        
        self.identityPath.URL = [proxyData valueForKey:kSPHAuthIdentityPath];
    }
    
    if (![self.window isKeyWindow]) {
        [self.window makeKeyAndOrderFront:self];
    }
    
    [self.window makeMainWindow];
    
    [[NSApplication sharedApplication] unhide:self.window];
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

-(IBAction)saveProxy:(id)sender;
{
    // Force identity file selection when needed
    if (1 == self.authChoice.selectedSegment && ![[self.identityPath.URL path] length]) {

        [self setAuthMethod:self.authChoice];
        
        return;
    }
    
    id identityPath_ = self.identityPath.URL;
    if (0 == self.authChoice.selectedSegment) {
        identityPath_ = [NSNull null];
    }
    
    NSInteger proxyIndex = [self proxyIndexFromTag: [sender tag]];
    NSMutableSet *proxyList = [SPHStandardUserDefaults() nonPropertyObjectForKey:kSPHProxyList];
    
    NSDictionary *authInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.authChoice, kSPHAuthType, identityPath_, kSPHAuthIdentityPath, nil];
    
    __block NSMutableDictionary *proxyData = [[self proxyDictionaryWithName:self.profileName.stringValue
                                                                   userName:self.userName.stringValue
                                                                   serverIp:self.serverIp.stringValue
                                                                 remotePort:self.remotePort.stringValue
                                                                  localPort:self.localPort.stringValue
                                                                andAuthInfo:authInfo] mutableCopy];
    
    // Get existing
    NSSet *originalProxy;
    NSDictionary *getOriginal = [self proxyDataFromIndex:proxyIndex];
    if (getOriginal) {
        originalProxy = [NSSet setWithObject:getOriginal];
    }
    
    // Get identical
    NSDictionary *editingProxy = [self bareInfoFromProxyData:proxyData];
    NSSet *duplicatedProxy = [proxyList objectsPassingTest:^BOOL(NSDictionary *enumeratingProxy, BOOL *stop) {
        
        NSDictionary *comparingProxy = [self bareInfoFromProxyData:enumeratingProxy];
        if ([editingProxy isEqualToDictionary:comparingProxy]) {
            
            // Skip original one
            NSInteger originalIndex = [[enumeratingProxy valueForKey:kSPHProxyIndex] integerValue];
            if (originalIndex == proxyIndex) {
                return NO;
            }
            
            *stop = YES;
            
            return YES;
        }
        
        return NO;
    }];
    
    __block NSInteger freeIndex = proxyIndex;
    
    // New proxy, with non duplicated data
    if (1 > proxyIndex && 1 > [duplicatedProxy count]) {
        // Increment proxyIndex -- Optimize
        NSOrderedSet *sortedProxyList = [NSOrderedSet orderedSetWithSet:proxyList];
        
        NSArray *enumeratinProxyList = [sortedProxyList sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSInteger index1 = [[obj1 objectForKey:kSPHProxyIndex] integerValue];
            NSInteger index2 = [[obj2 objectForKey:kSPHProxyIndex] integerValue];
            
            if (index1 < index2) {
                return NSOrderedAscending;
            }
            
            if (index1 > index2) {
                return NSOrderedDescending;
            }
            
            // Should never been
            return NSOrderedSame;
        }];
        
        NSLog(@"enumeratinProxyList: %@", enumeratinProxyList);
        
        __block NSInteger previousIndex = 0;
        [enumeratinProxyList enumerateObjectsUsingBlock:^(NSDictionary *proxyData, NSUInteger idx, BOOL *stop) {
            if (!previousIndex) {
                previousIndex = [[proxyData objectForKey:kSPHProxyIndex] integerValue];
                
                return;
            }
            
            NSInteger currentIndex = [[proxyData objectForKey:kSPHProxyIndex] integerValue];

            // Max proxy available reached
            if (currentIndex > 98) {
                *stop = YES;
                
                return;
            }
            
            if (currentIndex - previousIndex > 1) {
                freeIndex = previousIndex + 1;
                
                *stop = YES;
                
                return;
            }
            
            previousIndex = currentIndex;

        }];

        // No free index set
        if (1 > freeIndex) {
            if (1 > previousIndex) { // No previous index (first proxy)
                freeIndex = 1;
                
            } else { // A previous index with no free index set (second proxy)
                freeIndex = previousIndex + 1;
            }
        }
    } else {
        // Safety check - don't add/update if same proxy data is duplicated
        if (0 < [duplicatedProxy count]) {
            // TODO: Alert
            
            return;
        }

        // Editing proxy
        if (0 < proxyIndex && 0 < [originalProxy count]) {
            // ... clean
            [proxyList minusSet:originalProxy];
            
            // ... and backup
            [SPHStandardUserDefaults() setNonPropertyObject:proxyList forKey:kSPHProxyList];
            [SPHStandardUserDefaults() synchronize];
            
            int pid = (int)[self firstMacthingPidForProxyData:proxyData];;
            if (0 < pid) {
                kill(pid, SIGTERM);
            }
        }
        
    }

    // Fetch synchronized one
    proxyList = [SPHStandardUserDefaults() nonPropertyObjectForKey:kSPHProxyList];

    /*
    switch (self.authChoice.selectedSegment) {
        case 0:
            [proxyData setValue:[NSNull null] forKey:kSPHAuthIdentityPath];
            [proxyData setValue:kSPHAuthPass forKey:kSPHAuthType];
            
            break;
        case 1:
            [proxyData setValue:kSPHAuthIdentity forKey:kSPHAuthType];
            [proxyData setValue:identityPath_ forKey:kSPHAuthIdentityPath];
            
            break;
    }
    */

    [proxyData setValue:[NSNumber numberWithInteger:freeIndex] forKey:kSPHProxyIndex];
    
    NSDictionary *finalData = [NSDictionary dictionaryWithDictionary:proxyData];
    
    // Last safety check
    if (!freeIndex || [proxyList containsObject:finalData]) {
        // TODO: Alert
        
        return;
    }

    // ... so add
    [proxyList addObject:finalData];
    
    
    // .. and save
    [SPHStandardUserDefaults() setNonPropertyObject:proxyList forKey:kSPHProxyList];
    [SPHStandardUserDefaults() synchronize];
    
    self.networkInterfaces = nil;
    [self.statusMenu update];
    
    [self resetFormWindow];
    
    [[NSApplication sharedApplication] hide:self.window];
    
}


#pragma mark -- IBAction - Proxy Management
//  http://00f.net/2011/08/14/programmatically-changing-network-configuration-on-osx/
-(IBAction)enableProxy:(id)sender;
{
    [[NSApplication sharedApplication] hide:self.window];
    
    
    NSInteger ifaceIndex = [self ifaceIndexFromTag: [sender tag]];
    NSInteger proxyIndex = [self proxyIndexFromTag: [sender tag]];
    
    if (0 > ifaceIndex || ifaceIndex > ([self.networkInterfaces count] - 1)) {
        // TODO: Alert
        
        return;
    }
    
    NSDictionary *proxyData = [self proxyDataFromIndex:proxyIndex];
    NSDictionary *interfaceData = [self.networkInterfaces objectAtIndex:ifaceIndex];
    
    NSString *serviceID = [interfaceData valueForKey:@"ServiceID"];
    
    if (!serviceID) {
        // TODO: Alert
        
        return;
    }
    
    [self applyProxyForServiceID:serviceID withBlock:^BOOL(SCNetworkServiceRef networkService) {
        
        return [self setProxyData:proxyData forNetworkService:networkService];
        
    } andCommit:YES];
    
    self.networkInterfaces = nil;
    
    [self.statusMenu update];
}

-(IBAction)toggleProxy:(id)sender;
{
    [[NSApplication sharedApplication] hide:self.window];
    
    NSInteger proxyIndex = [self proxyIndexFromTag: [sender tag]];
    
    // Get existing
    NSDictionary *proxyData = [self proxyDataFromIndex:proxyIndex];
    if (!proxyData) {
        return;
    }
    
    NSError *error;
    
    NSString *userName_ = [proxyData valueForKey:kSPHUserName];
    NSString *serverIp_ = [proxyData valueForKey:kSPHServerIp];
    NSString *localPort_ = [proxyData valueForKey:kSPHLocalPort];
    NSString *remotePort_ = [proxyData valueForKey:kSPHRemotePort];

    NSString *userAtServer = [NSString stringWithFormat:@"%@@%@", userName_, serverIp_];
    
    int pid = (int)[self firstMacthingPidForProxyData:proxyData];
    
    if (0 < pid) {
        kill(pid, SIGTERM);
        
        NSLog(@"kill tunnel: %d", pid);
    } else {
        NSString *authType = [proxyData valueForKey:kSPHAuthType];
        
        if ([authType isEqualToString:kSPHAuthPass]) {
            NSBundle *bundle = [NSBundle bundleForClass:[self class]];
            NSString *pathToAuthentifier = [bundle pathForResource:@"SSHAskPass" ofType:@"sh"];
            
            if (!pathToAuthentifier) {
                NSLog(@"No SSH_ASKPASS script found");
                
                return;
            }

            NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
            [environment removeObjectForKey: @"SSH_AGENT_PID"];
            [environment removeObjectForKey: @"SSH_AUTH_SOCK"];
            [environment setObject: pathToAuthentifier forKey: @"SSH_ASKPASS"];
            [environment setObject:@":0" forKey:@"DISPLAY"];
            
            
            [NSTask stringByLaunchingPath:@"/usr/bin/ssh"
                            withArguments:[NSArray arrayWithObjects:@"-C2vTnNf", @"-D", localPort_, @"-p", remotePort_, userAtServer, nil]
                           andEnvironment:environment
                             inBackground:YES
                                    error:&error];
        } else {
            NSString *identityFile_ = [[proxyData valueForKey:kSPHAuthIdentityPath] path];
            
            if (![identityFile_ length]) {
                NSLog(@"No identity file provided");
                
                return;
            }
            
            [NSTask stringByLaunchingPath:@"/usr/bin/ssh"
                            withArguments:[NSArray arrayWithObjects:@"-C2qTnNf", @"-i", identityFile_, @"-D", localPort_, @"-p", remotePort_, userAtServer, nil]
                             inBackground:YES
                                    error:&error];
        }
        
        if (error) {
            NSLog(@"An error occurred launching process: %lu, %@", [error code], [error localizedDescription]);
            return;
        }
    }
}
@end
