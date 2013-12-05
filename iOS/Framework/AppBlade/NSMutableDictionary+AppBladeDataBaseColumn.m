//
//  NSDictionary+AppBladeDataBaseColumn.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "NSMutableDictionary+AppBladeDataBaseColumn.h"

@implementation NSMutableDictionary (AppBladeDataBaseColumn)

-(id)initColumnDictionaryNamed:(NSString*)name ofType:(NSString *)columnType withContraints:(AppBladeColumnConstraint)constraints additionalArgs:(NSString *)args {
    self = [super init];
    if (self != nil)
    {
        [self setColumnName:name];
        [self setColumnType:columnType];
        [self setColumnConstraints:constraints];
        [self setColumnAdditionalArgs:args];
    }
    return self;
}

-(NSString *)toSQLiteColumnDefinition;
{
    if(![self isValidColumnDefinition]) //essentially, we just ignore any bad column definitions
    {
        return @"";
    }
    //otherwise it's business as usual
    NSMutableString *toRet = [NSMutableString stringWithString:[self columnName]];
    if([self columnType] != nil)
    {
        [toRet appendFormat:@" %@",[self columnType]];
    }
    
    return toRet;
}

-(BOOL)isValidColumnDefinition {
    return [self columnName] != nil && [[self columnName] length] != 0; //column name must exist and cannot be nothing
}

-(NSString *)columnName {
    return [self valueForKey:kAppBladeColumnDictName];
}
-(void)setColumnName:(NSString *)name
{
    [self setValue:name forKey:kAppBladeColumnDictName];
}
-(NSString *)columnType {
    return [self valueForKey:kAppBladeColumnDictType];
}
-(void)setColumnType:(NSString *)type
{
    [self setValue:type forKey:kAppBladeColumnDictType];
}
-(AppBladeColumnConstraint)columnConstraints {
    NSNumber *fromStore = [self valueForKey:kAppBladeColumnDictContraints];
    return [fromStore integerValue];
}
-(void)setColumnConstraints:(AppBladeColumnConstraint)constraints
{
    NSNumber *toStore = [NSNumber numberWithInteger:constraints];
    [self setValue:toStore forKey:kAppBladeColumnDictContraints];
}

-(NSString *)columnAdditionalArgs {
    return [self valueForKey:kAppBladeColumnDictAdditionalArgs];
}
-(void)setColumnAdditionalArgs:(NSString *)args
{
    [self setValue:args forKey:kAppBladeColumnDictAdditionalArgs];
}


@end
