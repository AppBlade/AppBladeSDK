//
//  APBBase64DataEncoding.h
//  AppBlade
//
//  Created by AndrewTremblay on 1/28/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

void *NewBase64Decode(
                      const char *inputBuffer,
                      size_t length,
                      size_t *outputLength);

char *NewBase64Encode(
                      const void *inputBuffer,
                      size_t length,
                      bool separateLines,
                      size_t *outputLength);

@interface APBBase64DataEncoding : NSObject
+ (NSData *)dataFromBase64String:(NSString *)aString;
+ (NSString *)base64EncodedStringFromData:(NSData *)aData;

@end
