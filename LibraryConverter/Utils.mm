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

#import "Utils.h"

@implementation Utils

+ (void)showAlert:(NSString *)alertText withTitle:(NSString *)title withButton:(NSString *)button withStyle:(NSAlertStyle)style
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:title];
        [alert setInformativeText:alertText];
        [alert addButtonWithTitle:button];
        alert.alertStyle = style;
        [alert runModal];
    });
}

+ (void)showErrorAsyncMain:(NSString *)err
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlert:err withTitle:@"Error" withButton:@"Cancel" withStyle:NSAlertStyleCritical];
    });
}

+ (void)showError:(NSString *)err
{
    [self showAlert:err withTitle:@"Error" withButton:@"Cancel" withStyle:NSAlertStyleCritical];
}

+ (bool)askYesNo:(NSString *)err withTitle:(NSString *)title
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert setInformativeText:err];
    [alert addButtonWithTitle:@"No"];
    [alert addButtonWithTitle:@"Yes"];
    if ([alert runModal] == NSAlertFirstButtonReturn)
        return NO;
    return YES;
}

+ (NSString *)generateOutputNameFromInputPath:(NSString *)inputFilePath
                                  withPostfix:(NSString *)postfix
                                      withExt:(NSString *)ext
{
	NSMutableString *ret = [NSMutableString stringWithString:[inputFilePath stringByDeletingPathExtension]];
	[ret appendString:@"-"];
	[ret appendString:postfix];
	[ret appendString:@"."];
	[ret appendString:ext];
	return ret;
}

+ (NSString *)generateOutputNameFromInputPath:(NSString *)inputFilePath
                                      withExt:(NSString *)ext
{
	NSMutableString *ret = [NSMutableString stringWithString:[inputFilePath stringByDeletingPathExtension]];
	[ret appendString:@"."];
	[ret appendString:ext];
	return ret;	
}

+ (void)saveDictionary:(NSDictionary *)dictionary asPlist:(NSString *)plistPath
{
	if (dictionary == nil || plistPath == nil) {
		return;
	}
	NSError *error;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:dictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (plistData) {
        NSError* writeToFileError;
		if (![plistData writeToFile:plistPath  options:NSDataWritingAtomic error:&writeToFileError]) {
			NSLog(@"Error writing plist: %@", [writeToFileError localizedDescription]);
		}
    }
    else {
        NSLog(@"Error writing plist: %@", error);
    }
}

+ (NSDictionary*)dictionaryFromPlist:(NSString *)plistPath
{
	if (!plistPath)	{
		NSLog(@"Error reading plist: plistPath is null");
		return nil;
	}
	NSError *error = nil;
	NSPropertyListFormat format;
	bool isFileExist = [[NSFileManager defaultManager] isReadableFileAtPath:plistPath];
	if (!isFileExist) {
		NSLog(@"Error reading plist: %@. File doesn't exist", plistPath);
		return nil;
	}
	NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	NSDictionary *dictionary = (NSDictionary *)[NSPropertyListSerialization
												   propertyListWithData:plistXML
												   options: NSPropertyListMutableContainersAndLeaves
												   format:&format
												   error:&error];
	if (!dictionary)  {
		NSLog(@"Error reading plist: %@, format: %lu", error, format);
		return nil;
	}
	return dictionary;
}

+ (int)binarySearchNumber:(NSNumber *)number inSortedArray:(NSArray *)array
{
	if (number == nil || array == nil || [array count] == 0) {
		return -1;
	}
	unsigned int index = (unsigned)CFArrayBSearchValues((CFArrayRef)array,
                                                    CFRangeMake(0, [array count]),
                                                    (CFNumberRef)number,
                                                    (CFComparatorFunction)CFNumberCompare,
                                                    NULL);
	return (index < [array count] && [number isEqualToNumber:array[index]]) ? index : -1;
}
@end

@implementation FileHandler

@synthesize m_path;
@synthesize m_handler;
@synthesize m_configuration;

- (id)initWithPath:(NSString *)path
{
	return [self initWithPath:path withHistoryFromConfiguration:nil];
}

- (id)initWithPath:(NSString *)path withHistoryFromConfiguration:(ColumnTypesConfiguration *)configuration
{
	if (path == nil) {
		return nil;
	}
	if (self = [super init]) {
		self.m_path = path;
		m_configuration = [[ColumnTypesConfiguration alloc] init];
		if (configuration != nil) {
			[self copyHistoryFromColumnConfiguration: configuration];
		}
	}
	return self;
}

+ (id)fileHandlerWithPath:(NSString *)path
{
	return [[FileHandler alloc] initWithPath:path];
}

+ (id)fileHandlerWithPath:(NSString *)path withHistoryFromConfiguration:(ColumnTypesConfiguration *)configuration
{
	return [[FileHandler alloc] initWithPath:path];
}

- (bool)isWritable
{
	//check directory for access and file for write?
	bool isFileExist = [[NSFileManager defaultManager] fileExistsAtPath:m_path];
	bool isFileWritable = [[NSFileManager defaultManager] isWritableFileAtPath:m_path];
	return !isFileExist || isFileWritable;
}

- (BOOL)isOpenable
{
	FILE* f = fopen([m_path UTF8String], "at");
	BOOL ret = !!f;
	fclose(f);
	return ret;
}

+ (BOOL)isOpenable:(NSString *)path
{
	return [[FileHandler fileHandlerWithPath:path] isOpenable];
}

- (FILE *)m_handler
{
	if (!m_handler && m_path && ![m_path isEqualToString:@""])
		m_handler = fopen(m_path.UTF8String, "wt");

	return m_handler;
}

- (void)flush
{
	if ([FileHandler fileExistAtPathAndIsNotDirectory:m_path]) {
		[m_configuration saveConfigurationOfColumnTypesForFile: m_path];
	}	
	if (m_handler) {
		fflush(m_handler);
	}
}

- (void)close
{
	if (m_handler) {
		[self flush];
		fclose(m_handler);	
		m_handler = NULL;
	}
}

- (FileHandler *)copyHistoryFromColumnConfiguration:(ColumnTypesConfiguration *)configuration
{
	[m_configuration copyHistoryFromConfiguration:configuration];
	return self;
}

- (void)dealloc
{
	if (m_handler)
		fclose(m_handler);
}

+ (BOOL)fileExistAtPathAndIsNotDirectory:(NSString *)path
{
	BOOL isDirectory;
	return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory;	
}

@end
