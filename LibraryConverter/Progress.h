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

#include <functional>

#import "Utils.h"

@protocol Progress

- (void) setIndeterminate: (BOOL)inter;

- (void) start;
- (void) stop;
- (bool) setValue: (double) value; // Returns YES if cancel needed 

- (void) minorStart;
- (void) minorStop;
- (bool) minorSetValue: (double) value;

- (void) setText: (NSString *)text;
- (void) end; // Totally stop, close window, etc

- (bool) cancelled;

@end

@interface ProgressWindowController : NSWindowController <Progress>
{
	IBOutlet NSTextField *tfText;
	IBOutlet NSProgressIndicator *piMain;
	IBOutlet NSProgressIndicator *piMinor;
	NSInvocation* m_invocation;
	int numberOfArguments;	
	bool m_shouldCancel;
	BOOL m_isIndeterminate;
	BOOL m_enableCancelButton;
	NSObject *m_target;
    std::function<void(void)> method_on_completion;
	SEL m_method;
	IBOutlet NSButton* btnCancel;
}

@property (readwrite, retain) NSObject *m_target;
@property (assign) SEL m_method;
@property (nonatomic) std::function<void(void)> method_on_completion;
@property (readonly, getter=progressMain) NSProgressIndicator *piMain;
@property (getter=indeterminate, setter=setIndeterminate:) BOOL isIntermidiate;

-(id) init;
-(id) initWithCancel;
+ (ProgressWindowController *)progressWithTitle:(NSString *)title forTarget:(id)target andMethod:(SEL)method;
- (IBAction)cancel:(id) sender;

- (void) setIndeterminate: (BOOL)inter;
- (BOOL) indeterminate;
- (void) start;
- (void) stop;
- (bool) setValue: (double) value; // Returns YES if cancel needed 
- (void) setText: (NSString *)text;
- (void) end; // Totally stop, close window, etc
- (void) end1; // Totally stop, close window, etc; should work under el capitan

- (void) minorStart;
- (void) minorStop;
- (bool) minorSetValue: (double) value;
- (NSProgressIndicator*) progressMain;
- (bool) cancelled;
- (void) setEnableCancelButton: (BOOL) enable;

-(void) addParameterAsObject: (id) object;
-(void) addParameterAsInt: (int) value;
-(void) addParameterAsBool: (bool) value;
-(void) addParameterAsDouble: (double) value;
-(void) addParameterAsPointer: (void*) pointer;
-(void) getReturnValue: (void*) value;
-(void) setInvocationForTarget: (id) target withSelector: (SEL) selector;
-(void) runModal;
-(void) setTitle: (NSString*) title;

@end
