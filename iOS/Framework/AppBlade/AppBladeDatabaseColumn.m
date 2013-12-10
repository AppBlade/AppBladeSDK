//
//  NSMutableDictionary+AppBladeDataBaseColumn.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseColumn.h"

@implementation AppBladeDatabaseColumn

+(id)initColumnNamed:(NSString*)name ofType:(NSString *)columnType withContraints:(AppBladeColumnConstraint)constraints additionalArgs:(NSString *)args
{
    return [[AppBladeDatabaseColumn alloc] initColumnNamed:name ofType:columnType withContraints:constraints additionalArgs:args];
}


-(id)initColumnNamed:(NSString*)name ofType:(NSString *)columnType withContraints:(AppBladeColumnConstraint)constraints additionalArgs:(NSString *)args {
    self = [super init];
    if (self != nil)
    {
        [self setColumnName:name];
        [self setColumnType:columnType];
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
        [self setColumnType: [dictionary objectForKey: kAppBladeColumnDictType]];
        [self setConstraints: [(NSNumber *)[dictionary objectForKey:kAppBladeColumnDictContraints] integerValue]];
        [self setAdditionalArgs:[dictionary objectForKey:kAppBladeColumnDictAdditionalArgs]];
    }
    return self;
}

-(NSDictionary *)toDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        self.columnName, kAppBladeColumnDictName,
        self.columnType, kAppBladeColumnDictType,
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
    if([self columnType] != nil)
    {
        [toRet appendFormat:@" %@",[self columnType]];
    }


    if((self.constraints & AppBladeColumnConstraintNone)){
    
    }else{
        if(self.constraints & AppBladeColumnConstraintAffinityNone){
         [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityReal){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityInteger){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityNumeric){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintAffinityText){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintPrimaryKey){
            [toRet appendFormat:@" %@",kAppBladeColumnAffinityNone];
        }
        if(self.constraints & AppBladeColumnConstraintNotNull){
            [toRet appendFormat:@" %@",@"NOT NULL"];
        }
        if(self.constraints & AppBladeColumnConstraintUnique){
            [toRet appendFormat:@" %@",@"UNIQUE"];
        }
        if(self.constraints & AppBladeColumnConstraintAutoincrement){
            [toRet appendFormat:@" %@", @"AUTOINCREMENT"];
        }
    }
    
    return toRet;
}


-(BOOL) isValidColumnDefinition
{
    return (self.columnName != nil);
}
@end
