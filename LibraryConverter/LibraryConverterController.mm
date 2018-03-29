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
#import "LibraryConverterController.h"

#import "AES256.h"
#import "Utils.h"
#import "key.h"
#import "Progress.h"

@implementation LibraryConverterController

const char* toCString(NSString* path)
{
	return [path cStringUsingEncoding: NSUTF8StringEncoding];
}

- (BOOL)windowShouldClose:(id)sender
{
    // A nasty hack, but this app is unlikely to be used again
    [NSApp terminate:nil];
    return YES;
}

-(int) bckLibraryConvert: (ProgressWindowController*) wc
{
	[wc setIndeterminate: YES];
	[wc start];
	@try {
		NSString* blibPath = [[m_pcBlib URL] path];
		NSFileHandle* fhBlib = [NSFileHandle fileHandleForReadingAtPath: blibPath];
		if (nil == fhBlib)
		{
			return BAD_BLIB_FILE;
		}
		NSString* csvPath = [[m_pcCSV URL] path];
		[[NSFileManager defaultManager] createFileAtPath:csvPath contents: nil attributes: nil];
		NSFileHandle* fhCsv = [NSFileHandle fileHandleForWritingAtPath: csvPath];
		if (nil == fhCsv)
		{
			return BAD_CSV_FILE;
		}
		
		NSData* blibEncryptedData = [fhBlib readDataToEndOfFile];
		NSString* key = [NSString stringWithCString: g_key encoding: NSUTF8StringEncoding];
		NSData* decryptedData = [blibEncryptedData decryptWithKey: key];
		
		[fhCsv writeData: decryptedData];
		[fhBlib closeFile];
		[fhCsv closeFile];
		
	}
	@finally {
		[wc stop];
		[wc end];
	}
	return SUCCESS;
}

-(IBAction) convertClick: (id) sender
{
	ProgressWindowController* wc = [ProgressWindowController progressWithTitle: @"Convert" forTarget: self andMethod: @selector(bckLibraryConvert:)];
	[wc runModal];
	int retCode;
	[wc getReturnValue: &retCode];
	if (BAD_BLIB_FILE == retCode)
	{
		NSRunAlertPanel(@"Error", @"Can't open blib library file", @"Ok", nil, nil);	
	}
	if (BAD_CSV_FILE == retCode)
	{
		NSRunAlertPanel(@"Error", @"Can't open csv file", @"Ok", nil, nil);
	}
}

-(IBAction) selectBlibLibrary: (id) sender
{
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles: YES];
	[openPanel setCanChooseDirectories: NO];
	[openPanel setAllowsMultipleSelection: NO];
	[openPanel setAllowedFileTypes: [NSArray arrayWithObject: @"blib"]];
	if (NSOKButton == [openPanel runModal])
	{
		NSArray* selectedFiles = [openPanel URLs];
		if (0 != [selectedFiles count])
		{
			NSURL* libraryUrl = [selectedFiles objectAtIndex: 0];
			[m_pcBlib setURL: libraryUrl];
			NSString* csvPath = [Utils generateOutputNameFromInputPath: [libraryUrl path] 
															   withExt: @"csv"];
			[m_pcCSV setURL: [NSURL fileURLWithPath: csvPath]];
		}
	}
}

-(IBAction) selectCsvOutput: (id) sender
{
	NSSavePanel* savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes: [NSArray arrayWithObject: @"csv"]];
	if (NSOKButton == [savePanel runModal])
	{
		NSURL* output = [savePanel URL];
		if (nil == output)
		{
			[m_pcCSV setURL: output];
		}
	}
}
@end
