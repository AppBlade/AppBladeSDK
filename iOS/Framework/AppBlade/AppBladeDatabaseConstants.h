//
//  AppBladeDatabaseConstants.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#ifndef AppBlade_AppBladeDatabaseConstants_h
#define AppBlade_AppBladeDatabaseConstants_h


//sqlite does not enforce types, they instead use affinities for data columns
typedef NS_OPTIONS(NSUInteger, AppBladeColumnConstraint) {
    AppBladeColumnConstraintNone                    = 0,  //if this is set, all other constraints are ignored
    AppBladeColumnConstraintNotNull                 = 1 <<  1,
    AppBladeColumnConstraintAffinityText             = 1 <<  2,
    AppBladeColumnConstraintAffinityNumeric          = 1 <<  3,
    AppBladeColumnConstraintAffinityInteger          = 1 <<  4,
    AppBladeColumnConstraintAffinityReal             = 1 <<  5,
    AppBladeColumnConstraintAffinityNone             = 1 <<  6, //no multiple affinities, please
    AppBladeColumnConstraintPrimaryKey              = 1 <<  7, //too many primary keys can cause memory issues
    AppBladeColumnConstraintUnique                  = 1 <<  8,
    AppBladeColumnConstraintAutoincrement           = 1 <<  9
};  //todo1: more sql-related datatypes.
//todo2: increment, sorting, maybe link foreign keys into this enum somehow




static NSString* const kAppBladeColumnAffinityText      = @"TEXT";
static NSString* const kAppBladeColumnAffinityNumeric   = @"NUMERIC";
static NSString* const kAppBladeColumnAffinityInteger   = @"INTEGER";
static NSString* const kAppBladeColumnAffinityReal      = @"REAL";
static NSString* const kAppBladeColumnAffinityNone      = @"NONE";

//Our supported column constraints
static NSString* const kAppBladeColumnConstraintPrimaryKey      = @"PRIMARY KEY";
static NSString* const kAppBladeColumnConstraintNotNull         = @"NOT NULL";
static NSString* const kAppBladeColumnConstraintUnique          = @"UNIQUE";
static NSString* const kAppBladeColumnConstraintAutoincrement   = @"AUTOINCREMENT";

//Foreign Key
static NSString* const kAppBladeDatabaseForeignKeyFormat  = @"FOREIGN KEY(%@) REFERENCES %@(%@)"; //existing_column_name, secondary_table_name, secondary_table_primary_key_column (almost always id)

//default values must be handled separately, same with other CHECK functions, those can go in AdditionalArgs for now

//in the case of AppBladeDatabaseColumnTypeReference, pass a dictionary with {reftype, reference-table-name, index-value(s)},
typedef NS_OPTIONS(NSUInteger, AppBladeDatabaseRefType) {
    AppBladeDatabaseRefTypeInvalid                      = 0,
    AppBladeDatabaseRefTypeOneToOne                     = 1 << 1,
    AppBladeDatabaseRefTypeManyToOne                    = 1 << 2,
    AppBladeDatabaseRefTypeOneToMany                    = 1 << 3
};


#endif
