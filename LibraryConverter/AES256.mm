//
//  NSData+AESCrypt.m
//
//  AES Encrypt/Decrypt
//  Created by Jim Dovey and 'Jean'
//  See http://iphonedevelopment.blogspot.com/2009/02/strong-encryption-for-cocoa-cocoa-touch.html
//
//  BASE64 Encoding/Decoding
//  Copyright (c) 2001 Kyle Hammond. All rights reserved.
//  Original development by Dave Winer.
//
//  Put together by Michael Sedlaczek, Gone Coding on 2011-02-22
//

#import "AES256.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (AES256)
- (NSString *) toHex
{
    const char *utf8 = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableString *hex = [NSMutableString string];
    for (NSUInteger i=0; i < [self length]; i++)
	{
		[hex appendFormat:@"%02X" , *utf8++ & 0x00FF];
	}
    return [NSString stringWithFormat:@"%@", hex];
}
-(NSString*) fromHex
{
	NSString* str = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSMutableData *data= [NSMutableData data];
	unsigned char whole_byte;
	char byte_chars[3] = {'\0','\0','\0'};
	NSUInteger i;
	for (i=0; i < str.length/2; i++) {
		byte_chars[0] = [str characterAtIndex:i*2];
		byte_chars[1] = [str characterAtIndex:i*2+1];
		whole_byte = strtol(byte_chars, NULL, 16);
		[data appendBytes:&whole_byte length:1]; 
	}
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
- (NSString*) encryptedStringWithKey: (NSString *) key
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	data = [data encryptWithKey:key];
	NSString* encryptedString = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
	return encryptedString;
}
- (NSString*) decryptedStringWithKey: (NSString *) key
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	data = [data decryptWithKey: key];
	if (nil == data)
	{
		return nil;
	}
	NSString* decryptedString = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
	return decryptedString;
}
-(NSString*) md5
{
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[17];
	bzero(digest, sizeof(digest));
	CC_MD5([data bytes], (CC_LONG)[data length], digest);
	NSData* md5Data = [NSData dataWithBytes: digest length: 16];
	NSString* md5String = [[NSString alloc] initWithData: md5Data encoding:NSUTF8StringEncoding];
    return md5String;
}
@end

@implementation NSData (AES256)

- (NSData*) encryptWithKey: (NSString *) key
{
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
	[key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
	
	NSUInteger dataLength = [self length];
	
	//See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
										  keyPtr, kCCKeySizeAES256,
										  NULL /* initialization vector (optional) */,
										  [self bytes], dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
	}
	
	free(buffer);
	return nil;
}

- (NSData*) decryptWithKey: (NSString *) key
{
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
	[key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
	
	NSUInteger dataLength = [self length];
	
	//See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
										  keyPtr, kCCKeySizeAES256,
										  NULL /* initialization vector (optional) */,
										  [self bytes], dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
	}
	
	free(buffer); //free the buffer;
	return nil;
}

@end

