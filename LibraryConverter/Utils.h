/*
 * Copyright 2018 Frangou Lab
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Cocoa/Cocoa.h>

#import "ColumnTypesConfiguration.h"

static NSString *const CONFIG_ARG = @"config";
static NSString *const AUTOEXIT_ARG = @"autoexit";
static NSString *const AUTORUN_ARG = @"autorun";

@interface Utils : NSObject

+ (NSString *)generateOutputNameFromInputPath:(NSString *)inputFilePath
								 withPostfix:(NSString *)postfix
									 withExt:(NSString *)ext;
+ (NSString *)generateOutputNameFromInputPath:(NSString *)inputFilePath
									 withExt:(NSString *)ext;
+ (NSDictionary *)dictionaryFromPlist:(NSString *)plist;
+ (void)saveDictionary:(NSDictionary *) dictionary asPlist:(NSString*) plistPath;
+ (int)binarySearchNumber:(NSNumber *)number inSortedArray:(NSArray*) array;

+ (void)showAlert:(NSString *)alertText withTitle:(NSString *)title withButton:(NSString *)button withStyle:(NSAlertStyle)style;
+ (void)showError:(NSString *)err;
+ (void)showErrorAsyncMain:(NSString *)err;
+ (bool)askYesNo:(NSString *)err withTitle:(NSString *)title;

@end


//use only for writing to file. FileHandler uses mode "wt"
@interface FileHandler : NSObject
{
	NSString *m_path;
	FILE *m_handler;
}

@property (readwrite, copy) NSString *m_path;
@property (readonly) FILE *m_handler;

@property (retain) ColumnTypesConfiguration *m_configuration;
- (id)initWithPath:(NSString *)path withHistoryFromConfiguration:(ColumnTypesConfiguration *)configuration;
+ (id)fileHandlerWithPath:(NSString *)path withHistoryFromConfiguration:(ColumnTypesConfiguration *)configuration;
- (FileHandler *)copyHistoryFromColumnConfiguration:(ColumnTypesConfiguration *)configuration;

- (id)initWithPath:(NSString *)path;
+ (id)fileHandlerWithPath:(NSString *)path;
- (bool)isWritable;
- (BOOL)isOpenable;
+ (BOOL)isOpenable:(NSString *) path;
- (void)flush;
- (void)close;
+ (BOOL)fileExistAtPathAndIsNotDirectory:(NSString *)path;

@end
