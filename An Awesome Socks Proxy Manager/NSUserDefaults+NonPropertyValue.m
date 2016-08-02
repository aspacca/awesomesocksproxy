//
//  NSUserDefaults+NonPropertyValue.m
//  Awesome Menubar
//
//  Created by Andrea Spacca on 11/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSUserDefaults+NonPropertyValue.h"
NSUserDefaults *SPHStandardUserDefaults() {
    return [NSUserDefaults standardUserDefaults];
}

@implementation NSUserDefaults (NonPropertyValue)
- (id) nonPropertyObjectForKey:(NSString *)defaultName;
{
    NSData *nonPropertyObject = [self objectForKey:defaultName];
    
    if (![nonPropertyObject respondsToSelector:@selector(encodeWithCoder:)]) {
        return nil;
    }
    
    id decodedObject = [NSKeyedUnarchiver unarchiveObjectWithData: nonPropertyObject];
    
    return decodedObject;
}

- (void) setNonPropertyObject:(id)value forKey:(NSString *)defaultName;
{
    if (![value respondsToSelector:@selector(encodeWithCoder:)]) {
        return;
    }
    
    NSData *nonPropertyObject = [NSKeyedArchiver archivedDataWithRootObject:value];
    
    [self setObject:nonPropertyObject forKey:defaultName];    
}

@end
