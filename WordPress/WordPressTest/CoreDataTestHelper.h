//
//  CoreDataTestHelper.h
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataTestHelper : NSObject

+ (id)sharedHelper;

- (void)reset;

- (void)setModelName:(NSString *)modelName;
- (BOOL)migrateToModelName:(NSString *)modelName;

- (NSManagedObject *)insertEntityIntoMainContextWithName:(NSString *)entityName;
- (NSManagedObject *)insertEntityIntoBackgroundContextWithName:(NSString *)entityName;
- (NSArray *)allObjectsInMainContextForEntityName:(NSString *)entityName;
- (NSArray *)allObjectsInBackgroundContextForEntityName:(NSString *)entityName;

@end
