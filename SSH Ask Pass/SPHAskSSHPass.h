//
//  SPHAskSSHPass.h
//  SPHAskSSHPass
//
//  Created by Andrea Spacca on 04/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SPHAskSSHPass  : NSObject <NSApplicationDelegate> {
}

@property (nonatomic, strong) NSString *fifo;
@property (nonatomic, strong) NSString *capt;

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSTextFieldCell *caption;
@property (assign) IBOutlet NSSecureTextField *password;

-(IBAction)doAuthentication:(id)sender;

@end
