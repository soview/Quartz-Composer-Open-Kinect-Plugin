//
//  RGBOutputImageProvider.mm
//  ImageWithKinect
//
//  Created by Samuel Toulouse on 26/11/10.
//  Copyright 2010 Pirate & Co. All rights reserved.
//

#import "RGBOutputImageProvider.h"
#include "libfreenect.h"
#import "ImageWithKinectPlugIn.h"

@implementation RGBOutputImageProvider

@synthesize _plugin;

- (id) initWithPlugin:(ImageWithKinectPlugIn*)plugin {
	self = [super init];
	if (self != nil) {
		_plugin = [plugin retain];
		_colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	return self;
}

- (void) dealloc {
	[_plugin release];
	CGColorSpaceRelease(_colorSpace);
	[super dealloc];
}


- (NSRect) imageBounds {
	return NSMakeRect(0.0f, 0.0f, 640.0f, 480.0f);
}

- (CGColorSpaceRef) imageColorSpace {
	return _colorSpace;
}

- (NSArray*)supportedBufferPixelFormats {
	return [NSArray arrayWithObjects:QCPlugInPixelFormatARGB8,
			QCPlugInPixelFormatBGRA8,
			nil];	
}

- (BOOL) renderToBuffer:(void*)baseAddress
        withBytesPerRow:(NSUInteger)rowBytes
            pixelFormat:(NSString*)format
              forBounds:(NSRect)bounds {

	if (pthread_mutex_trylock(&_plugin->_backbuf_mutex)) {
		if (_plugin->_got_rgb) {
			uint8_t* tmp = _plugin->_rgb_front;
			_plugin->_rgb_front = _plugin->_rgb_mid;
			_plugin->_rgb_mid = tmp;
			_plugin->_got_rgb = 0;
		}
	
		pthread_mutex_unlock(&_plugin->_backbuf_mutex);
	}
	
	if (format == QCPlugInPixelFormatARGB8) {
		uint8_t* buf = (uint8_t*)baseAddress;
		for (int i = 0; i < bounds.size.height; ++i) {
			for (int j = 0; j < bounds.size.width; ++j) {
				buf[j * 4 + i * (int)bounds.size.width * 4 + 0] = 0xFF;
				buf[j * 4 + i * (int)bounds.size.width * 4 + 1] = _plugin->_rgb_front[j * 3 + i * (int)bounds.size.width * 3 + 0];
				buf[j * 4 + i * (int)bounds.size.width * 4 + 2] = _plugin->_rgb_front[j * 3 + i * (int)bounds.size.width * 3 + 1];
				buf[j * 4 + i * (int)bounds.size.width * 4 + 3] = _plugin->_rgb_front[j * 3 + i * (int)bounds.size.width * 3 + 2];
			}
		}
	} else if (format == QCPlugInPixelFormatBGRA8) {		
		uint8_t* buf = (uint8_t*)baseAddress;
		for (int i = 0; i < bounds.size.height; ++i) {
			for (int j = 0; j < bounds.size.width; ++j) {
				buf[j * 4 + i * (int)bounds.size.width * 4 + 0] = _plugin->_rgb_front[j * 3 + i * (int)bounds.size.width * 3 + 2];
				buf[j * 4 + i * (int)bounds.size.width * 4 + 1] = _plugin->_rgb_front[j * 3 + i * (int)bounds.size.width * 3 + 1];
				buf[j * 4 + i * (int)bounds.size.width * 4 + 2] = _plugin->_rgb_front[j * 3 + i * (int)bounds.size.width * 3 + 0];
				buf[j * 4 + i * (int)bounds.size.width * 4 + 3] = 0xFF;
			}
		}
	}
	
	return YES;
}

@end
