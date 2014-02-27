//
//  NSMutableDictionary+AppBladeDatabaseColumn.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseColumn.h"

@implementation AppBladeDatabaseColumn

+(id)initColumnNamed:(NSString*)name  withContraints:(AppBladeColumnConstraint)constraints additionalArgs:(NSString *)args
{
    return [[AppBladeDatabaseColumn alloc] initColumnNamed:name withContraints:constraints additionalArgs:args];
}


-(id)initColumnNamed:(NSString*)name withContraints:(AppBladeColumnConstraint)constraints additionalArgs:(NSString *)args {
    self = [super init];
    if (self != nil)
    {
        [self setColumnName:name];
        [self setConstraints:constraints];
        [self setAdditionalArgs:args];
    }
    return self;
}

-(id)initWithDict:(NSDictionary *)dictionary
{
    self = [super init];
    if (self != nil)
    {
        [self setColumnName: [dictionary objectForKey:kAppBladeColumnDictName]];
        [self setConstraints: [(NSNumber *)[dictionary objectForKey:kAppBladeColumnDictContraints] integerValue]];
        [self setAdditionalArgs:[dictionary objectForKey:kAppBladeColumnDictAdditionalArgs]];
    }
    return self;
}

-(NSDictionary *)toDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        self.columnName, kAppBladeColumnDictName,
        [NSNumber numberWithInteger:self.constraints], kAppBladeColumnDictContraints,
        self.additionalArgs, kAppBladeColumnDictAdditionalArgs, nil];
}

-(NSString *)toSQLiteColumnDefinition;
{
    if(![self isValidColumnDefinition]) //essentially, we just ignore any bad column definitions
    {
        return @"";
    }
    //otherwise it's business as usual
    NSMutableString *toRet = [NSMutableString stringWithString:[self columnName]];

//    if(!(self.constraints & AppBladeColumnConstraintNone)){
//        // for when we start updating columns, we should put better logic here
//    }else{
        if(self.constraints & AppBladeColumnConstraintAffinityNone){
         [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityReal){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityInteger];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityInteger){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityInteger];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityNumeric){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityNumeric];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityText){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityText];
        }
        if(self.constraints & AppBladeColumnConstraintPrimaryKey){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintNotNull){
            [toRet appendFormat:@" %@", kAppBladeColumnConstraintNotNull];
        }
        if(self.constraints & AppBladeColumnConstraintUnique){
            [toRet appendFormat:@" %@", kAppBladeColumnConstraintUnique];
        }
        if(self.constraints & AppBladeColumnConstraintAutoincrement){
            [toRet appendFormat:@" %@", kAppBladeColumnConstraintAutoincrement];
        }
//    }
    
    return toRet;
}


-(BOOL) isValidColumnDefinition
{
    return (self.columnName != nil);
}
@end
