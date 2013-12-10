//
//  AppBladeDatabaseObject.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

//represents a single row in a table
@interface AppBladeDatabaseObject : NSObject

    @property (nonatomic, strong) NSString *tableName; //the table this object currently resides
    @property (nonatomic, strong, getter = getId) NSString *dbRowId; //the id this row has in the table


@end
