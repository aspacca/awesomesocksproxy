//
//  NSUserDefaults+NonPropertyValue.h
//  Awesome Menubar
//
//  Created by Andrea Spacca on 11/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark -- Static
NSUserDefaults *SPHStandardUserDefaults(void);

@interface NSUserDefaults (NonPropertyValue)

- (id) nonPropertyObjectForKey:(NSString *)defaultName;
- (void) setNonPropertyObject:(id)value forKey:(NSString *)defaultName;

@end
