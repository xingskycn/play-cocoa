//
//  PLAImageCache.m
//  Play Cocoa
//
//  Created by Danny Greg on 19/04/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLAAlbumArtworkImageCache.h"

#import "AFNetworking.h"

//***************************************************************************

CGFloat const PLAAlbumArtworkImageCacheImageSize = 47.0;

//***************************************************************************

@interface PLAAlbumArtworkImageCache ()

@property (nonatomic, readonly) NSOperationQueue *artworkDownloadQueue;

- (NSURL *)localImageLocationForURL:(NSURL *)url;
- (NSImage *)cachedImageForURL:(NSURL *)url;

@end

//***************************************************************************

@implementation PLAAlbumArtworkImageCache

@synthesize artworkDownloadQueue = _artworkDownloadQueue;

+ (id)sharedCache
{
	static PLAAlbumArtworkImageCache *sharedCache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedCache = [[PLAAlbumArtworkImageCache alloc] init];
	});
	
	return sharedCache;
}

- (id)init
{	
	self = [super init];
	if (self == nil)
		return nil;
	
	_artworkDownloadQueue = [[NSOperationQueue alloc] init];	

	return self;
}

- (void)dealloc
{
	[_artworkDownloadQueue release], _artworkDownloadQueue = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark API

- (void)imageForURL:(NSURL *)imageURL withCompletionBlock:(void(^)(NSImage *image, NSError *error))completionBlock
{
	NSImage *localImage = [self cachedImageForURL:imageURL];
	if (localImage != nil) {
		if (completionBlock != nil)
			completionBlock(localImage, nil);
		return;
	}
	
	void (^callCompletionBlockWithImageError)(NSImage *image, NSError *error) = ^ (NSImage *image, NSError *error) 
	{
		if (completionBlock == nil)
			return;
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			completionBlock(image, error);
		});
	};
	
	NSURLRequest *artworkRequest = [NSURLRequest requestWithURL:imageURL];
	AFHTTPRequestOperation *requestOperation = [[[AFHTTPRequestOperation alloc] initWithRequest:artworkRequest] autorelease];
	[requestOperation setCompletionBlockWithSuccess: ^ (AFHTTPRequestOperation *operation, id responseObject) 
	{
		NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:responseObject];
		if (imageRep == nil) {
			callCompletionBlockWithImageError(nil, [NSError errorWithDomain:@"org.play.play-item" code:-1 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not create image from downloaded data.", nil) forKey:NSLocalizedDescriptionKey]]);
			return;
		}
		
		imageRep.size = NSMakeSize(PLAAlbumArtworkImageCacheImageSize, PLAAlbumArtworkImageCacheImageSize);
		NSData *imageData = [imageRep representationUsingType:NSPNGFileType properties:nil];
		[imageData writeToURL:[self localImageLocationForURL:imageURL] atomically:YES];
		
		NSImage *returnImage = [[[NSImage alloc] initWithSize:imageRep.size] autorelease];
		[returnImage addRepresentation:imageRep];
		callCompletionBlockWithImageError(returnImage, nil);
		
	} failure: ^ (AFHTTPRequestOperation *operation, NSError *error) 
	{
		callCompletionBlockWithImageError(nil, error);
	}];
	
	[self.artworkDownloadQueue addOperation:requestOperation];
}

#pragma mark -
#pragma mark Helpers

- (NSURL *)localImageLocationForURL:(NSURL *)url
{
	NSString *fileName = [url lastPathComponent]; //The stub is what we are going to use… we should probably take a PLATrack and key it against the artist and album name… but this will do for now.
	
	NSString *cachesFolderPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	cachesFolderPath = [[cachesFolderPath stringByAppendingPathComponent:@"org.play.play-item"] stringByAppendingPathComponent:@"Artwork"];
	NSURL *returnLocation = [[NSURL fileURLWithPath:cachesFolderPath] URLByAppendingPathComponent:fileName];
	
	return returnLocation;
}

- (NSImage *)cachedImageForURL:(NSURL *)url
{
	return [[[NSImage alloc] initWithContentsOfURL:[self localImageLocationForURL:url]] autorelease]; //This does the smart thing and returns nil if no image exists at that path
}

@end