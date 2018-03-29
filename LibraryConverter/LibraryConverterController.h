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

enum ConvertStatus
{
	SUCCESS,
	BAD_BLIB_FILE,
	BAD_CSV_FILE
};

@interface LibraryConverterController : NSWindow<NSWindowDelegate>
{
	IBOutlet NSPathControl* m_pcBlib;
	IBOutlet NSPathControl* m_pcCSV;
}

- (IBAction)selectBlibLibrary:(id)sender;
- (IBAction)selectCsvOutput:(id)sender;
- (IBAction)convertClick:(id)sender;

@end
