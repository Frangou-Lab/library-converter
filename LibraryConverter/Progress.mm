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
#import "Progress.h"

@implementation ProgressWindowController
{
    __strong NSObject *last_argument_;
}
@synthesize m_target;
@synthesize m_method;
@synthesize method_on_completion;

- (id)init
{
	if (self = [super initWithWindowNibName:@"ProgressWindow"])
	{
		m_shouldCancel = NO;
		numberOfArguments = 2;
		m_enableCancelButton = NO;
	}
	return self;
}

- (id)initWithCancel
{
	if (self = [self init])
	{
		m_enableCancelButton = YES;
	}
	return self;
}

+ (ProgressWindowController *)progressWithTitle:(NSString *)title forTarget:(id)target andMethod:(SEL)method;
{
	ProgressWindowController* wc = [[ProgressWindowController alloc] init];
	wc.m_target = target;
	wc.m_method = method;
	[wc setTitle:title];
	return wc;
}

- (IBAction)cancel:(id)sender
{
	m_shouldCancel = YES;
}

- (void)setEnableCancelButton:(BOOL)enable
{
	if (btnCancel)
		btnCancel.enabled = enable;
	else
		m_enableCancelButton = enable;
}

- (void)runModal
{
	if (!m_invocation && m_target && m_method) {
		[self setInvocationForTarget:m_target withSelector:m_method];
	}
	// assert (nil != m_invocation);
	NSModalSession session = [NSApp beginModalSessionForWindow:[self window]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [m_invocation performSelector:@selector(invoke) withObject:nil];
        if (method_on_completion && [last_argument_ isMemberOfClass:[FileHandler class]]) {
            method_on_completion();
            last_argument_ = nil;
        }
    });

    NSLog(@"Starting modal loop");
    
    for (;;)
    {
        NSInteger code = [NSApp runModalSession:session];
        if (code != NSModalResponseCancel)
        {
            NSLog(@"RunModalSession returned %li", (long)code);
            break;
        }
        [NSThread sleepForTimeInterval:0.05]; // Do nothing for 50ms. Unnoticeable, but saves a lot of CPU time.
    }
    NSLog(@"Ending modal loop");
	[NSApp endModalSession:session];
    NSLog(@"Ended modal loop");
}

- (void)windowDidLoad
{
	[piMain setUsesThreadedAnimation:YES];
	[piMain setIndeterminate:m_isIndeterminate];
	[btnCancel setEnabled:m_enableCancelButton];
}

- (void)setIndeterminate:(BOOL)inter
{
	if (nil != piMain) {
		[piMain setIndeterminate:inter];
	} else {
		m_isIndeterminate = inter;
	}
}

- (BOOL)indeterminate
{
	if (nil != piMain)
	{
		m_isIndeterminate = [piMain isIndeterminate];
	} 
	return m_isIndeterminate;
}

- (void)start
{
	[piMain setDoubleValue:0];
	[piMain startAnimation:self];
}

- (void)stop
{
	[piMain stopAnimation:self];
	[piMain setDoubleValue:0];
}

- (bool)setValue:(double)value // Returns YES if cancel needed
{
	if ([piMain isIndeterminate])
		[piMain incrementBy:0.5];
	else
		[piMain setDoubleValue:value];
	return m_shouldCancel;
}

- (void)minorStart
{
	[piMinor setHidden:NO];
	[piMinor setDoubleValue:0];
	[piMinor startAnimation:self];
}

- (void)minorStop
{
	[piMinor stopAnimation:self];
	[piMinor setDoubleValue:0];
	[piMinor setHidden:YES];
}

- (bool)minorSetValue:(double)value
{
	[piMinor setDoubleValue:value];
	return m_shouldCancel;
}

- (bool)cancelled
{
	return m_shouldCancel;
}

- (void)setText:(NSString *)text
{
	[tfText setStringValue:text];
}
   
- (void)end // Totally stop, close window, etc
{
	[self close];
	[[NSApplication sharedApplication] abortModal];
}

- (void)end1 // Totally stop, close window, etc
{
    [[NSApplication sharedApplication] abortModal];
    [self close];
}

- (NSProgressIndicator *)progressMain
{
	return piMain;
}

- (void)setInvocationForTarget:(id)target withSelector:(SEL)selector
{
	NSMethodSignature* signature = [[target class] instanceMethodSignatureForSelector:selector];
    m_invocation = [NSInvocation invocationWithMethodSignature:signature];
	[m_invocation setTarget:target];
	[m_invocation setSelector:selector];
	[m_invocation setArgument:(void *)&self atIndex:numberOfArguments++];
}

- (void)addParameterAsPointer:(void *)pointer
{
	if (!m_invocation && m_target && m_method)
	{
		[self setInvocationForTarget:m_target withSelector:m_method];
	}
	assert(nil != m_invocation);
	[m_invocation setArgument:pointer atIndex:numberOfArguments++];
}

- (void)addParameterAsObject:(id)object
{
    last_argument_ = object;
	[self addParameterAsPointer:(void *)&object];
}

- (void)addParameterAsInt:(int)value
{
	[self addParameterAsPointer:&value];
}

- (void)addParameterAsDouble:(double)value
{
	[self addParameterAsPointer:&value];
}

- (void)addParameterAsBool:(bool)value
{
	[self addParameterAsPointer: &value];	
}

- (void)getReturnValue:(void *)value
{
	[m_invocation getReturnValue:value];
}

- (void)setTitle:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window setTitle:title];
    });
}

@end
