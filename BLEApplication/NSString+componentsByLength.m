//
//  NSString+componentsByLength.m
//  BLEApplication
//
//  Created by Apple on 16/11/4.
//  Copyright © 2016年 Tsao. All rights reserved.
//

#import "NSString+componentsByLength.h"

@implementation NSString (componentsByLength)
- (NSArray *) componentSaparetedByLength:(NSUInteger) length{
    NSMutableArray *array = [NSMutableArray new];
    NSRange range = NSMakeRange(0, length);
    NSString *subString = nil;
    while (range.location + range.length <= self.length) {
        subString = [self substringWithRange:range];
        [array addObject:subString];
        //Edit
        range.location = range.length + range.location;
        //Edit
        range.length = length;
    }
    
    if(range.location<self.length){
        subString = [self substringFromIndex:range.location];
        [array addObject:subString];
    }
    return array;
}
@end
