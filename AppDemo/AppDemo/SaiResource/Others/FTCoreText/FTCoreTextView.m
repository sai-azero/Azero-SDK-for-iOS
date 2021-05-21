//
//  FTCoreTextView.m
//  FTCoreText
//
//  Created by Francesco Freezone <cescofry@gmail.com> on 20/07/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import "FTCoreTextView.h"
#import <CoreText/CoreText.h>
//#import "CinLogger.h"

//#import "SDImageCache.h"
//#import "SDWebImageManager.h"

#define SYSTEM_VERSION_LESS_THAN(v)			([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


NSString * const FTCoreTextTagDefault = @"default";
NSString * const FTCoreTextTagImage = @"img";
NSString * const FTCoreTextTagSmile = @"smile";
NSString * const FTCoreTextTagBullet = @"quote";
NSString * const FTCoreTextTagPage = @"page";
NSString * const FTCoreTextTagLink = @"link";

NSString * const FTCoreTextDataType = @"type";
NSString * const FTCoreTextDataURL = @"url";
NSString * const FTCoreTextDataImage = @"image";
NSString * const FTCoreTextDataName = @"FTCoreTextDataName";
NSString * const FTCoreTextDataFrame = @"FTCoreTextDataFrame";
NSString * const FTCoreTextDataAttributes = @"FTCoreTextDataAttributes";

typedef enum {
	FTCoreTextTagTypeOpen,
	FTCoreTextTagTypeClose,
	FTCoreTextTagTypeSelfClose
} FTCoreTextTagType;

@interface FTCoreTextNode : NSObject

@property (nonatomic, assign) FTCoreTextNode	*supernode;
@property (nonatomic, retain) NSArray			*subnodes;
@property (nonatomic, copy)   FTCoreTextStyle	*style;
@property (nonatomic, assign) NSRange			styleRange;
@property (nonatomic, assign) BOOL				isClosed;
@property (nonatomic, assign) NSInteger			startLocation;
@property (nonatomic, assign) BOOL				isLink;
@property (nonatomic, assign) BOOL				isImage;
@property (nonatomic, assign) BOOL				isBullet;
@property (nonatomic, retain) NSString			*imageName;
@property (nonatomic, retain) UIImage           *image;
@property (nonatomic, assign) CGRect            nodeBounds;

- (NSString *)descriptionOfTree;
- (NSString *)descriptionToRoot;
- (void)addSubnode:(FTCoreTextNode *)node;
- (void)adjustStylesAndSubstylesRangesByRange:(NSRange)insertedRange;
- (void)insertSubnode:(FTCoreTextNode *)subnode atIndex:(NSUInteger)index;
- (void)insertSubnode:(FTCoreTextNode *)subnode beforeNode:(FTCoreTextNode *)node;
- (FTCoreTextNode *)previousNode;
- (FTCoreTextNode *)nextNode;
- (NSUInteger)nodeIndex;
- (FTCoreTextNode *)subnodeAtIndex:(NSUInteger)index;

@end

@implementation FTCoreTextNode

@synthesize supernode = _supernode;
@synthesize subnodes = _subnodes;
@synthesize style = _style;
@synthesize styleRange = _styleRange;
@synthesize isClosed = _isClosed;
@synthesize isLink = _isLink;
@synthesize isImage = _isImage;
@synthesize startLocation = _startLocation;
@synthesize isBullet = _isBullet;
@synthesize imageName = _imageName;
@synthesize image = _image;
@synthesize nodeBounds = _nodeBounds;

- (NSArray *)subnodes
{
	if (_subnodes == nil) {
		_subnodes = [NSMutableArray new];
	}
	return _subnodes;
}

- (void)addSubnode:(FTCoreTextNode *)node
{
	[self insertSubnode:node atIndex:[_subnodes count]];
}

- (void)insertSubnode:(FTCoreTextNode *)subnode atIndex:(NSUInteger)index
{
	subnode.supernode = self;
	
	NSMutableArray * subnodes = (NSMutableArray *)self.subnodes;
	if (index <= [_subnodes count]) {
		[subnodes insertObject:subnode atIndex:index];
	}
	else {
		[subnodes addObject:subnode];
	}
}

- (void)insertSubnode:(FTCoreTextNode *)subnode beforeNode:(FTCoreTextNode *)node
{
	NSInteger existingNodeIndex = [_subnodes indexOfObject:node];
	if (existingNodeIndex == NSNotFound) {
		[self addSubnode:subnode];
	}
	else {
		[self insertSubnode:subnode atIndex:existingNodeIndex];
	}
}

- (NSInteger)numberOfParents
{
	NSInteger returnedValue = 0;
	FTCoreTextNode *node = self.supernode;
	while (node) {
		returnedValue++;
		node = node.supernode;
	}
	return returnedValue;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@\t-\t%@ - \t%@", [super description], _style.name, NSStringFromRange(_styleRange)];
}

- (NSString *)descriptionToRoot
{
	NSMutableString *description = [NSMutableString stringWithString:@"\n\n"];
	
	FTCoreTextNode *node = self;
	do {
		[description insertString:[NSString stringWithFormat:@"%@",[self description]] atIndex:0];
		
		for (int i = 0; i < [self numberOfParents]; i++) {
			[description insertString:@"\t" atIndex:0];
		}
		[description insertString:@"\n" atIndex:0];
		node = node.supernode;
		
	} while (node);
	
	return description;
}

- (NSString *)descriptionOfTree
{
	NSMutableString *description = [NSMutableString string];
	for (int i = 0; i < [self numberOfParents]; i++) {
        [description appendString:@"\t"];
	}
	[description appendFormat:@"%@\n", [self description]];
	for (FTCoreTextNode *node in _subnodes) {
		[description appendString:[node descriptionOfTree]];
	}
	return description;
}

- (NSArray *)_allSubnodes
{
	NSMutableArray *subnodes = [NSMutableArray new];
	for (FTCoreTextNode *node in _subnodes) {
		[subnodes addObject:node];
		if (node.subnodes) [subnodes addObjectsFromArray:[node _allSubnodes]];
	}
	
	return subnodes;
}

//return an array of nodes starting with the current and recursively adding all its child nodes
- (NSArray *)allSubnodes
{
	//NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSArray * allSubnodes = [[self _allSubnodes] copy];
//	[pool release];
	NSMutableArray *returnedArray = [NSMutableArray arrayWithObject:self];
	[returnedArray addObjectsFromArray:allSubnodes];
//	[allSubnodes release];
	return returnedArray;
}

- (void)adjustStylesAndSubstylesRangesByRange:(NSRange)insertedRange
{
	NSRange range = self.styleRange;
	if (range.length + range.location > insertedRange.location) {
		range.location += insertedRange.length;
	}
	self.styleRange = range;
	
	for (FTCoreTextNode *node in _subnodes) {
		[node adjustStylesAndSubstylesRangesByRange:insertedRange];
	}
}

- (NSUInteger)nodeIndex
{
	return [_supernode.subnodes indexOfObject:self];
}

- (FTCoreTextNode *)subnodeAtIndex:(NSUInteger)index
{
	if (index < [_subnodes count]) {
		return [_subnodes objectAtIndex:index];
	}
	return nil;
}

- (FTCoreTextNode *)previousNode
{
	NSUInteger index = [self nodeIndex];
	if (index != NSNotFound) {
		return [_supernode subnodeAtIndex:index - 1];
	}
	return nil;
}

- (FTCoreTextNode *)nextNode
{
	NSUInteger index = [self nodeIndex];
	if (index != NSNotFound) {
		return [_supernode subnodeAtIndex:index + 1];
	}
	return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.isClosed = YES;
    }
    return self;
}

- (void)dealloc
{
//	[_subnodes release];
//	[_style release];
//	[_imageName release];
//    [_image release];
//	[super dealloc];
}

@end



@interface FTCoreTextView ()

@property (nonatomic, assign) CTFramesetterRef framesetter;
@property (nonatomic, retain) FTCoreTextNode *rootNode;

@property (nonatomic, strong) NSSet *myTouchSet;
@property (nonatomic, strong) UIEvent *myEvent;

- (void)updateFramesetterIfNeeded;
- (void)processText;
CTFontRef CTFontCreateFromUIFont(UIFont *font);
NSTextAlignment UITextAlignmentFromCoreTextAlignment(FTCoreTextAlignement alignment);
NSInteger rangeSort(NSString *range1, NSString *range2, void *context);
- (void)drawImages;
- (void)doInit;
- (void)didMakeChanges;
- (NSString *)defaultTagNameForKey:(NSString *)tagKey;
- (NSMutableArray *)divideTextInPages:(NSString *)string;

@end

@implementation FTCoreTextView

@synthesize text = _text;
@synthesize processedString = _processedString;
@synthesize path = _path;
@synthesize URLs = _URLs;
@synthesize images = _images;
@synthesize delegate = _delegate;
@synthesize framesetter = _framesetter;
@synthesize rootNode = _rootNode;
@synthesize shadowColor = _shadowColor;
@synthesize shadowOffset = _shadowOffset;
@synthesize attributedString = _attributedString;

#pragma mark - Tools methods

NSInteger rangeSort(NSString *range1, NSString *range2, void *context)
{
    NSRange r1 = NSRangeFromString(range1);
	NSRange r2 = NSRangeFromString(range2);
	
    if (r1.location < r2.location)
        return NSOrderedAscending;
    else if (r1.location > r2.location)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

CTFontRef CTFontCreateFromUIFont(UIFont *font)
{
    CTFontRef ctFont = CTFontCreateWithName((CFStringRef)font.fontName,
                                            font.pointSize,
                                            NULL);
    return ctFont;
}

NSTextAlignment UITextAlignmentFromCoreTextAlignment(FTCoreTextAlignement alignment)
{
	switch (alignment) {
		case FTCoreTextAlignementCenter:
			return NSTextAlignmentCenter;
			break;
		case FTCoreTextAlignementRight:
			return NSTextAlignmentRight;
			break;
		default:
			return NSTextAlignmentLeft;
			break;
	}
}

#pragma mark - FTCoreTextView business
#pragma mark -

- (void)changeDefaultTag:(NSString *)coreTextTag toTag:(NSString *)newDefaultTag
{
	if ([_defaultsTags objectForKey:coreTextTag] == nil) {
		[NSException raise:NSInvalidArgumentException format:@"%@ is not a default tag of FTCoreTextView. Use the constant FTCoreTextTag constants.", coreTextTag];
	}
	else {
		[_defaultsTags setObject:newDefaultTag forKey:coreTextTag];
	}
}

- (NSString *)defaultTagNameForKey:(NSString *)tagKey
{
	return [_defaultsTags objectForKey:tagKey];
}

- (BOOL)isValidTagName:(NSString *)tagKey {
    
    return [_defaultsTags objectForKey:tagKey] != nil ||
    [_styles objectForKey:tagKey] != nil;
}

- (void)didMakeChanges
{
	_coreTextViewFlags.updatedAttrString = NO;
	_coreTextViewFlags.updatedFramesetter = NO;
}

#pragma mark - UI related
- (NSArray *)allImageNames {
    NSMutableArray *imageNames = [[NSMutableArray alloc] initWithCapacity:_images.count];
    for (FTCoreTextNode *node in _images) {
        [imageNames addObject:node.imageName];
    }
    return imageNames ;
}

- (NSDictionary *)dataForPoint:(CGPoint)point
{
	NSMutableDictionary * returnedDict = [NSMutableDictionary dictionary];
	
	CGMutablePathRef mainPath = CGPathCreateMutable();
    if (!_path) {
        CGPathAddRect(mainPath, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    }
    else {
        CGPathAddPath(mainPath, NULL, _path);
    }
	
    CTFrameRef ctframe = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), mainPath, NULL);
    CGPathRelease(mainPath);
	
    NSArray *lines = (NSArray *)CTFrameGetLines(ctframe);
    NSInteger lineCount = [lines count];
    CGPoint origins[lineCount];
    
    if (lineCount != 0) {
		
		CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), origins);
		
		for (int i = 0; i < lineCount; i++) {
			CGPoint baselineOrigin = origins[i];
			//the view is inverted, the y origin of the baseline is upside down
			baselineOrigin.y = CGRectGetHeight(self.frame) - baselineOrigin.y;
			
			CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
			CGFloat ascent, descent;
			CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
			
			CGRect lineFrame = CGRectMake(baselineOrigin.x, baselineOrigin.y - ascent, lineWidth, ascent + descent);
			
			if (CGRectContainsPoint(lineFrame, point)) {
				//we look if the position of the touch is correct on the line
				CFIndex index = CTLineGetStringIndexForPosition(line, point);
				NSArray *urlsKeys = [_URLs allKeys];
				
				for (NSString *key in urlsKeys) {
					NSRange range = NSRangeFromString(key);
					if (index >= range.location && index < range.location + range.length) {
						NSURL * url = [_URLs objectForKey:key];
						if (url) {
                            [returnedDict setObject:FTCoreTextTagLink forKey:FTCoreTextDataType];
                            [returnedDict setObject:url forKey:FTCoreTextDataURL];
                        }
						break;
					}
				}
                if (returnedDict.count == 0) {
                    FTCoreTextNode *imageNode = [self testPoint:point inLine:line];
                    if (imageNode) {
                        [returnedDict setObject:FTCoreTextTagImage forKey:FTCoreTextDataType];
                        [returnedDict setObject:imageNode.imageName forKey:FTCoreTextDataImage];
                    }
                }
            }
            else{
                // because the (large) image location not fit a text line
                // so if image click, the point not in lineFrame
                FTCoreTextNode *imageNode = [self testPoint:point inLine:line];
                if (imageNode) {
                    [returnedDict setObject:FTCoreTextTagImage forKey:FTCoreTextDataType];
                    [returnedDict setObject:imageNode.imageName forKey:FTCoreTextDataImage];
                }
            }
			if (returnedDict.count > 0) break;
		}
	}
	
	CFRelease(ctframe);
	
	return returnedDict;
}

- (FTCoreTextNode *)testPoint:(CGPoint)point inLine:(CTLineRef)line {
    for (FTCoreTextNode *imageNode in _images)
    {
        for (id runObj in (NSArray *)CTLineGetGlyphRuns(line))
        {
            CTRunRef run = (__bridge CTRunRef)runObj;
            CFRange runRange = CTRunGetStringRange(run);
            // if the image range locate in a CFRun
            if (runRange.location <= imageNode.styleRange.location &&
                runRange.location+ runRange.length > imageNode.styleRange.location)
            {
                if (CGRectContainsPoint(imageNode.nodeBounds, point)) {
                    return imageNode;
                }
            }
        }
    }
    return nil;
}

- (void)updateFramesetterIfNeeded
{
    if (!_coreTextViewFlags.updatedAttrString) {
		if (_framesetter != NULL) CFRelease(_framesetter);
        
		_framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
 		_coreTextViewFlags.updatedAttrString = YES;
    }
}

/*!
 * @abstract get the supposed size of the drawn text
 *
 */

- (CGSize)suggestedSizeConstrainedToSize:(CGSize)size
{
	CGSize suggestedSize;
    [self updateFramesetterIfNeeded];
    if (_framesetter == NULL) {
        return CGSizeZero;
    }
    suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, 0), NULL, size, NULL);
    suggestedSize = CGSizeMake(ceilf(suggestedSize.width), ceilf(suggestedSize.height));
    return suggestedSize;
}

/*!
 * @abstract handy method to fit to the suggested height in one call
 *
 */

- (void)fitToSuggestedHeight
{
	CGSize suggestedSize = [self suggestedSizeConstrainedToSize:CGSizeMake(CGRectGetWidth(self.frame), MAXFLOAT)];
	CGRect viewFrame = self.frame;
	viewFrame.size.height = suggestedSize.height;
	self.frame = viewFrame;
}

#pragma mark - Text processing

- (NSString *)summaryText {
    if (_text.length>10) {
        return [_text substringToIndex:10];
    }
    else {
        return _text;
    }
}

- (NSString *)spaceForEmotionImage:(UIImage *)image withStyle:(FTCoreTextStyle *)style{
    NSString *fillChar;
    if (!style.color && style.color != [UIColor clearColor]) {
        fillChar = @" ";
    }
    else {
        fillChar = @"-";
        style.color = [UIColor clearColor];
    }
    NSMutableString *str = [[NSMutableString alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    //写在这个中间的代码,都不会被编译器提示-Wdeprecated-declarations类型的警告
    CGFloat spaceWidth = [fillChar sizeWithFont:style.font].width;
#pragma clang diagnostic pop

    
    int count = (int)ceil((image.size.width/spaceWidth));
    for (int i=0; i<count; ++i) {
        [str appendString:fillChar];
    }
    return str ;
}

- (NSString *)faceFileName:(NSString *)elemName {
    NSScanner *scanner = [NSScanner scannerWithString:elemName];
    if ([scanner scanUpToString:@"/" intoString:nil]) {
        [scanner scanString:@"/" intoString:nil];
        NSString *fileName = nil;
        if ([scanner scanUpToString:@"." intoString:&fileName])
            return fileName;
    }
    return elemName;
}

- (void)processLinkClose:(FTCoreTextNode *)currentSupernode tagRange:(NSRange)tagRange processedString:(NSMutableString *)processedString
{
    //replace active string with url text
    NSRange elementContentRange = NSMakeRange(currentSupernode.startLocation, tagRange.location - currentSupernode.startLocation);
    NSString * elementContent = [processedString substringWithRange:elementContentRange];
    NSRange pipeRange = [elementContent rangeOfString:@"|^|"];
    NSString * urlString = nil;
    NSString * urlDescription = nil;
    if (pipeRange.location != NSNotFound)
    {
        urlString = [elementContent substringToIndex:pipeRange.location];
        urlDescription = [elementContent substringFromIndex:pipeRange.location + 3];
        urlDescription = [urlDescription stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (urlDescription.length == 0)
        {
            urlDescription = urlString;
        }
    }
    else {
        urlString = elementContent;
        urlDescription = elementContent;
    }
    if ([urlDescription hasPrefix:@"[img]"] && [urlDescription hasSuffix:@"[/img]"]) {
        //
        urlDescription = urlString;
    }
    
    [processedString replaceCharactersInRange:NSMakeRange(elementContentRange.location, elementContentRange.length + tagRange.length) withString:urlDescription];
//    if (![urlString hasPrefix:@"http://"]) {
//        urlString = [NSString stringWithFormat:@"http://%@", urlString];
//    }
    NSURL * url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSRange urlDescriptionRange = NSMakeRange(elementContentRange.location, [urlDescription length]);
    if (url) {
        [_URLs setObject:url forKey:NSStringFromRange(urlDescriptionRange)];
    }
    
    currentSupernode.styleRange = urlDescriptionRange;
}

- (void)processImageClose:(FTCoreTextNode *)currentSupernode tagRange:(NSRange)tagRange processedString:(NSMutableString *)processedString
{
    NSRange elementContentRange = NSMakeRange(currentSupernode.startLocation, tagRange.location - currentSupernode.startLocation);
    NSString * elementContent = [processedString substringWithRange:elementContentRange];
    UIImage *img = nil;
    NSString *lines = [NSString stringWithFormat:@"%C",0xFFFC];
    img = [UIImage imageNamed:elementContent];
    if (img == nil)
    {
        img = [UIImage imageWithContentsOfFile:elementContent];
    }
//    if (img) {
//        lines = [self spaceForEmotionImage:img withStyle:currentSupernode.style];
//    }
//    else {
//        // if can't load the local image, just show the element.
//        lines = [self faceFileName:elementContent];
//    }
    
    if (img)
    {
//        currentSupernode.style.leading = img.size.height;
        currentSupernode.style.leading = 2;
    }
    else {
        currentSupernode.image = nil;
//        infoLog(@"FTCoreTextView - Couldn't find image '%@' in main bundle", elementContent);
    }
    currentSupernode.image = img;
    currentSupernode.imageName = elementContent;
    currentSupernode.styleRange = NSMakeRange(elementContentRange.location, lines.length);
    [_images addObject:currentSupernode];
    
    [processedString replaceCharactersInRange:NSMakeRange(elementContentRange.location, elementContentRange.length + tagRange.length) withString:lines];
    
   
    
}

/*!
 * @abstract remove the tags from the text and create a tree representation of the text
 *
 */

- (void)processText
{
    if (!_text || [_text length] == 0) return;
	
	[_URLs removeAllObjects];
    [_images removeAllObjects];
	
	FTCoreTextNode * rootNode = [FTCoreTextNode new] ;
	rootNode.style = [_styles objectForKey:[self defaultTagNameForKey:FTCoreTextTagDefault]];
    
	FTCoreTextNode *currentSupernode = rootNode;
	
	NSMutableString *processedString = [NSMutableString stringWithString:_text];
	
	BOOL finished = NO;
	NSRange remainingRange = NSMakeRange(0, [processedString length]);
	
	NSString *regEx = @"\\[[^\\[](/){0,1}.*?( /){0,1}\\]";
    
	while (!finished) {
		NSRange tagRange = [processedString rangeOfString:regEx options:NSRegularExpressionSearch range:remainingRange];
		if (tagRange.location == NSNotFound) {
			if (currentSupernode != rootNode && !currentSupernode.isClosed) {
//                infoLog(@"FTCoreTextView - Can't find close tag '%@' which at position %d - \n%@",
//                      currentSupernode.style.name, currentSupernode.startLocation, [self summaryText]);
                // try to cloase the tag.
                NSString *closeTag = [NSString stringWithFormat:@"[/%@]", currentSupernode.style.name];
                [processedString appendString:closeTag];
                remainingRange.length += closeTag.length;
                continue;
			}
			finished = YES;
            continue;
		}
//        取出匹配标签
        NSString * fullTag = [processedString substringWithRange:tagRange];
        FTCoreTextTagType tagType;
        
        if ([fullTag rangeOfString:@"[/"].location == 0) {
            tagType = FTCoreTextTagTypeClose;
        }
        else if ([fullTag rangeOfString:@"/]"].location == NSNotFound && [fullTag rangeOfString:@" /]"].location == NSNotFound) {
            tagType = FTCoreTextTagTypeOpen;
        }
        else {
            tagType = FTCoreTextTagTypeSelfClose;
        }
        
//        得到标签名
		NSArray * tagsComponents = [fullTag componentsSeparatedByString:@" "];
		NSString * tagName = (tagsComponents.count > 0) ? [tagsComponents objectAtIndex:0] : fullTag;
        tagName = [tagName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[ /]"]];
        // if tag name not register, ignore it and advance
		if (![self isValidTagName:tagName]) {
            remainingRange.location = tagRange.location+1;
            remainingRange.length = [processedString length] - remainingRange.location;
            continue;
        }
//        根据标签名得到标签相对应的属性
        FTCoreTextStyle * style = [_styles objectForKey:tagName];
        
        if (style == nil) {
            style = [_styles objectForKey:[self defaultTagNameForKey:FTCoreTextTagDefault]];
        }
        switch (tagType) {
            case FTCoreTextTagTypeOpen:
            {
                if (currentSupernode.isLink || currentSupernode.isImage) {
//                    infoLog(@"FTCoreTextView - You can't open a new tag inside a '%@' tag - \n%@",
//                          currentSupernode.style.name, [self summaryText]);
                    // skip this tag
                    remainingRange.location = tagRange.location+tagRange.length;
                    remainingRange.length = [processedString length] - remainingRange.location;
                    continue;
                }
//                创建新节点
                FTCoreTextNode * newNode = [FTCoreTextNode new];
                newNode.style = style;
                newNode.startLocation = tagRange.location;
                
                if ([tagName isEqualToString:[self defaultTagNameForKey:FTCoreTextTagLink]]) {
                    newNode.isLink = YES;
                }
                else if ([tagName isEqualToString:[self defaultTagNameForKey:FTCoreTextTagBullet]]) {
                    newNode.isBullet = YES;
                    
                    NSString * appendedString = [NSString stringWithFormat:@"%@\t", newNode.style.bulletCharacter];
                    [processedString insertString:appendedString atIndex:tagRange.location + tagRange.length];
                    
                    //bullet styling
                    FTCoreTextStyle *bulletStyle = [FTCoreTextStyle new];
                    bulletStyle.name = @"_FTBulletStyle";
                    bulletStyle.font = newNode.style.bulletFont;
                    bulletStyle.color = newNode.style.bulletColor;
                    bulletStyle.applyParagraphStyling = NO;
                    bulletStyle.paragraphInset = UIEdgeInsetsMake(0, 0, 0, newNode.style.paragraphInset.left);
                    
                    FTCoreTextNode *bulletNode = [FTCoreTextNode new];
                    bulletNode.style = bulletStyle;
//                    [bulletStyle release];
                    bulletNode.styleRange = NSMakeRange(tagRange.location, [appendedString length]);
                    
                    [newNode addSubnode:bulletNode];
//                    [bulletNode release];
                }
                else if ([tagName isEqualToString:[self defaultTagNameForKey:FTCoreTextTagImage]] ||
                         [tagName isEqualToString:[self defaultTagNameForKey:FTCoreTextTagSmile]])
                {
                    newNode.isImage = YES;
                }
                
                [processedString replaceCharactersInRange:tagRange withString:@""];
                [currentSupernode addSubnode:newNode];
//                [newNode release];
                
                currentSupernode = newNode;
                currentSupernode.isClosed = NO;
                remainingRange.location = tagRange.location;
                remainingRange.length = processedString.length - tagRange.location;
            }
                break;
            case FTCoreTextTagTypeClose:
            {
                if ((![currentSupernode.style.name isEqualToString:[self defaultTagNameForKey:FTCoreTextTagDefault]] && ![currentSupernode.style.name isEqualToString:tagName]) ) {
//                    infoLog(@"FTCoreTextView - Closed tag '%@' not match open tag '%@'-\n%@",
//                          tagName, currentSupernode.style.name, [self summaryText]);
                    // skip this tag
                    remainingRange.location = tagRange.location+tagRange.length;
                    remainingRange.length = processedString.length - remainingRange.location;
                    
                    continue;
                }
                if (currentSupernode.isClosed) {
                    // no open tag
//                    infoLog(@"FTCoreTextView - Closed tag '%@' havn't open tag-\n%@",
//                          tagName, [self summaryText]);
                    remainingRange.location = tagRange.location += tagRange.length;
                    remainingRange.length = processedString.length - remainingRange.location;
                    continue;
                }
                
                currentSupernode.isClosed = YES;
                
                if (currentSupernode.isLink) {
                    [self processLinkClose:currentSupernode tagRange:tagRange processedString:processedString];
                }
                else if (currentSupernode.isImage) {
                    [self processImageClose:currentSupernode tagRange:tagRange processedString:processedString];
                }
                else {
                    currentSupernode.styleRange = NSMakeRange(currentSupernode.startLocation, tagRange.location - currentSupernode.startLocation);
                    [processedString replaceCharactersInRange:tagRange withString:@""];
                }
                
                if ([currentSupernode.style.appendedCharacter length] > 0) {
                    [processedString insertString:currentSupernode.style.appendedCharacter atIndex:currentSupernode.styleRange.location + currentSupernode.styleRange.length];
                    NSRange newStyleRange = currentSupernode.styleRange;
                    newStyleRange.length += [currentSupernode.style.appendedCharacter length];
                    currentSupernode.styleRange = newStyleRange;
                }
                
                if (style.paragraphInset.top > 0) {
                    if (![style.name isEqualToString:[self defaultTagNameForKey:FTCoreTextTagBullet]] ||  [[currentSupernode previousNode].style.name isEqualToString:[self defaultTagNameForKey:FTCoreTextTagBullet]]) {
                        
                        //fix: add a new line for each new line and set its height to 'top' value
                        [processedString insertString:@"\n" atIndex:currentSupernode.startLocation];
                        NSRange topSpacingStyleRange = NSMakeRange(currentSupernode.startLocation, [@"\n" length]);
                        FTCoreTextStyle *topSpacingStyle = [[FTCoreTextStyle alloc] init];
                        topSpacingStyle.name = [NSString stringWithFormat:@"_FTTopSpacingStyle_%@", currentSupernode.style.name];
                        topSpacingStyle.minLineHeight = currentSupernode.style.paragraphInset.top;
                        topSpacingStyle.maxLineHeight = currentSupernode.style.paragraphInset.top;
                        FTCoreTextNode * topSpacingNode = [[FTCoreTextNode alloc] init];
                        topSpacingNode.style = topSpacingStyle;
//                        [topSpacingStyle release];
                        
                        topSpacingNode.styleRange = topSpacingStyleRange;
                        
                        [currentSupernode.supernode insertSubnode:topSpacingNode beforeNode:currentSupernode];
//                        [topSpacingNode release];
                        
                        [currentSupernode adjustStylesAndSubstylesRangesByRange:topSpacingStyleRange];
                    }
                }
                
                remainingRange.location = currentSupernode.styleRange.location + currentSupernode.styleRange.length;
                remainingRange.length = [processedString length] - remainingRange.location;
                
//                回到父节点
                currentSupernode = currentSupernode.supernode;
            }
                break;
            case FTCoreTextTagTypeSelfClose:
            {
                FTCoreTextNode * newNode = [FTCoreTextNode new];
                newNode.style = style;
                [processedString replaceCharactersInRange:tagRange withString:newNode.style.appendedCharacter];
                newNode.styleRange = NSMakeRange(tagRange.location, [newNode.style.appendedCharacter length]);
                [currentSupernode addSubnode:newNode];
//                [newNode release];
                
                remainingRange.location = tagRange.location;
                remainingRange.length = [processedString length] - tagRange.location;
            }
                break;
        }
	}
	
	rootNode.styleRange = NSMakeRange(0, [processedString length]);
	
	self.rootNode = rootNode;
	self.processedString = processedString;
}

/*!
 * @abstract Remove all the tags and return a clean text to be used
 *
 */

+ (NSString *)stripTagsForString:(NSString *)string
{
    FTCoreTextView *instance = [[FTCoreTextView alloc] initWithFrame:CGRectZero];
    [instance setText:string];
    [instance processText];
    NSString *result = [[instance.processedString copy] init];//check
//    [instance release];
    return result;
}

/*!
 * @abstract divide the text in different pages according to the tags <_page/> found
 *
 */

+ (NSArray *)pagesFromText:(NSString *)string
{
    FTCoreTextView *instance = [[FTCoreTextView alloc] initWithFrame:CGRectZero];
    NSArray *result = [instance divideTextInPages:string];
//	[instance release];
    return (NSArray *)result;
}

/*!
 * @abstract divide the text in different pages according to the tags <_page/> found
 *
 */

- (NSMutableArray *)divideTextInPages:(NSString *)string
{
    NSMutableArray *result = [NSMutableArray array];
    NSUInteger prevStart = 0;
    while (YES) {
        NSRange rangeStart = [string rangeOfString:[NSString stringWithFormat:@"[%@/]", [self defaultTagNameForKey:FTCoreTextTagPage]]];
		if (rangeStart.location == NSNotFound) rangeStart = [string rangeOfString:[NSString stringWithFormat:@"[%@ /]", [self defaultTagNameForKey:FTCoreTextTagPage]]];
		
        if (rangeStart.location != NSNotFound) {
            NSString *page = [string substringWithRange:NSMakeRange(prevStart, rangeStart.location)];
            [result addObject:page];
            string = [string stringByReplacingCharactersInRange:rangeStart withString:@""];
            prevStart = rangeStart.location;
        }
        else {
            NSString *page = [string substringWithRange:NSMakeRange(prevStart, (string.length - prevStart))];
            [result addObject:page];
            break;
        }
    }
    return result;
}

#pragma mark Styling

- (void)addStyle:(FTCoreTextStyle *)style
{
    [_styles setValue:style forKey:style.name];
	[self didMakeChanges];
    if ([self superview]) [self setNeedsDisplay];
}

- (void)addStyles:(NSArray *)styles
{
	for (FTCoreTextStyle *style in styles) {
		[_styles setValue:style forKey:style.name];
	}
	[self didMakeChanges];
    if ([self superview]) [self setNeedsDisplay];
}

- (void)removeAllStyles
{
	[_styles removeAllObjects];
	[self didMakeChanges];
    if ([self superview]) [self setNeedsDisplay];
}

//attribute值相同则会合并成一个CTRun
- (void)applyStyle:(FTCoreTextStyle *)style inRange:(NSRange)styleRange onString:(NSMutableAttributedString **)attributedString
{
//    名称
    NSString *name = [NSString stringWithFormat:@"%@_%lu_%lu",style.name,(unsigned long)styleRange.location,(unsigned long)styleRange.length];
    [*attributedString addAttribute:(id)FTCoreTextDataName
                              value:(id)name
                              range:styleRange];
    
    if ([style.name isEqualToString:FTCoreTextTagImage])
    {
        CTRunDelegateCallbacks imageCallbacks;
        imageCallbacks.version = kCTRunDelegateVersion1;
        imageCallbacks.dealloc = RunDelegateDeallocCallback;
        imageCallbacks.getAscent = RunDelegateGetAscentCallback;
        imageCallbacks.getDescent = RunDelegateGetDescentCallback;
        imageCallbacks.getWidth = RunDelegateGetWidthCallback;
        CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallbacks, nil);
        [*attributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:styleRange];
    }
//    前景色
	[*attributedString addAttribute:(id)kCTForegroundColorAttributeName
							  value:(id)style.color.CGColor
							  range:styleRange];
//	下划线
	if (style.isUnderLined) {
		NSNumber *underline = [NSNumber numberWithInt:kCTUnderlineStyleSingle];
		[*attributedString addAttribute:(id)kCTUnderlineStyleAttributeName
								  value:(id)underline
								  range:styleRange];
	}
//	font
	CTFontRef ctFont = CTFontCreateFromUIFont(style.font);
	[*attributedString addAttribute:(id)kCTFontAttributeName
							  value:(__bridge id)ctFont
							  range:styleRange];
	CFRelease(ctFont);
	
//    字符间隔
    // disable kerning
    NSNumber *kern = [NSNumber numberWithFloat:0];
    [*attributedString addAttribute:(id)kCTKernAttributeName
                              value:kern
                              range:styleRange];
    
	CTTextAlignment alignment = style.textAlignment;
	CGFloat maxLineHeight = style.maxLineHeight;
	CGFloat minLineHeight = style.minLineHeight;
	CGFloat paragraphLeading = style.leading;//行间距
	
	CGFloat paragraphSpacingBefore = style.paragraphInset.top;
	CGFloat paragraphSpacingAfter = style.paragraphInset.bottom;
	CGFloat paragraphFirstLineHeadIntent = style.paragraphInset.left;
	CGFloat paragraphHeadIntent = style.paragraphInset.left;
	CGFloat paragraphTailIntent = style.paragraphInset.right;
	
	//if (SYSTEM_VERSION_LESS_THAN(@"5.0")) {
	paragraphSpacingBefore = 0;
	//}
	
	CFIndex numberOfSettings = 9;
	CGFloat tabSpacing = 28.f;
	
	BOOL applyParagraphStyling = style.applyParagraphStyling;
	
	if ([style.name isEqualToString:[self defaultTagNameForKey:FTCoreTextTagBullet]]) {
		applyParagraphStyling = YES;
	}
	else if ([style.name isEqualToString:@"_FTBulletStyle"]) {
		applyParagraphStyling = YES;
		numberOfSettings++;
		tabSpacing = style.paragraphInset.right;
		paragraphSpacingBefore = 0;
		paragraphSpacingAfter = 0;
		paragraphFirstLineHeadIntent = 0;
		paragraphTailIntent = 0;
	}
	else if ([style.name hasPrefix:@"_FTTopSpacingStyle"]) {
		[*attributedString removeAttribute:(id)kCTParagraphStyleAttributeName range:styleRange];
	}
	
	if (applyParagraphStyling) {
		
		CTTextTabRef tabArray[] = { CTTextTabCreate(0, tabSpacing, NULL) };
		
		CFArrayRef tabStops = CFArrayCreate( kCFAllocatorDefault, (const void**) tabArray, 1, &kCFTypeArrayCallBacks );
		CFRelease(tabArray[0]);
		
		CTParagraphStyleSetting settings[] = {
			{kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
			{kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &maxLineHeight},
			{kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minLineHeight},
			{kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore},
			{kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacingAfter},
			{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &paragraphFirstLineHeadIntent},
			{kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &paragraphHeadIntent},
			{kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &paragraphTailIntent},
			{kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &paragraphLeading},
			{kCTParagraphStyleSpecifierTabStops, sizeof(CFArrayRef), &tabStops}//always at the end
		};
		
		CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, numberOfSettings);
		[*attributedString addAttribute:(id)kCTParagraphStyleAttributeName
								  value:(__bridge id)paragraphStyle
								  range:styleRange];
		CFRelease(tabStops);
		CFRelease(paragraphStyle);
	}
}
void RunDelegateDeallocCallback(void* refCon)
{
    
}

CGFloat RunDelegateGetAscentCallback(void* refCon)
{
    CGFloat height = 14;
    //    NSString *imageName = (__bridge NSString *)refCon;
    //    height = [UIImage imageNamed:imageName].size.height;
    return height;
    
}

CGFloat RunDelegateGetDescentCallback(void *refCon)
{
    return 4;
}

CGFloat RunDelegateGetWidthCallback(void *refCon)
{
    CGFloat width = 20;
    //    NSString *imageName = (__bridge NSString*)refCon;
    //    width = [UIImage imageNamed:imageName].size.width;
    return width;
}


#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame andAttributedString:nil];
}

- (id)initWithFrame:(CGRect)frame andAttributedString:(NSAttributedString *)attributedString
{
	self = [super initWithFrame:frame];
	if (self) {
		_attributedString = attributedString;
		[self doInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self doInit];
    }
    return self;
}

- (void)doInit
{
	_framesetter = NULL;
	_styles = [[NSMutableDictionary alloc] init];
	_URLs = [[NSMutableDictionary alloc] init];
    _images = [[NSMutableArray alloc] init];
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	self.contentMode = UIViewContentModeRedraw;
	[self setUserInteractionEnabled:YES];
	
	FTCoreTextStyle *defaultStyle = [FTCoreTextStyle styleWithName:FTCoreTextTagDefault];
	[self addStyle:defaultStyle];
	
	FTCoreTextStyle *linksStyle = [defaultStyle copy];
	linksStyle.color = [UIColor blueColor];
	linksStyle.name = FTCoreTextTagLink;
	[_styles setValue:linksStyle forKey:linksStyle.name];
//	[linksStyle release];
	
	_defaultsTags = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      FTCoreTextTagDefault, FTCoreTextTagDefault,
					  FTCoreTextTagLink, FTCoreTextTagLink,
					  FTCoreTextTagImage, FTCoreTextTagImage,
                      FTCoreTextTagSmile, FTCoreTextTagSmile,
					  FTCoreTextTagPage, FTCoreTextTagPage,
					  FTCoreTextTagBullet, FTCoreTextTagBullet,
					  nil];
}

- (void)dealloc
{
    //????
	if (_framesetter) CFRelease(_framesetter);
	if (_path) CGPathRelease(_path);
//	[_rootNode release];
//    [_text release];
//    [_styles release];
//    [_processedString release];
//    [_URLs release];
//    [_images release];
//	[_shadowColor release];
//	[_attributedString release];
//	[_defaultsTags release];
//    [super dealloc];
}

#pragma mark - Custom Setters

- (void)setText:(NSString *)text
{
//    [_text release];
    _text = text ;
	_coreTextViewFlags.textChangesMade = YES;
	[self didMakeChanges];
    if ([self superview])
        [self setNeedsDisplay];
}

- (void)setPath:(CGPathRef)path
{
    _path = CGPathRetain(path);
	[self didMakeChanges];
    if ([self superview])
        [self setNeedsDisplay];
}

- (void)setShadowColor:(UIColor *)shadowColor
{
//	[_shadowColor release];
	_shadowColor = shadowColor;
	if ([self superview])
        [self setNeedsDisplay];
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
	_shadowOffset = shadowOffset;
	if ([self superview])
        [self setNeedsDisplay];
}

#pragma mark - Custom Getters
- (NSArray *)styles
{
	return [_styles allValues];
}
//属性化字符串
- (NSAttributedString *)attributedString
{
	if (!_coreTextViewFlags.updatedAttrString) {
 		_coreTextViewFlags.updatedAttrString = YES;
		
//        转化字符串
		if (_processedString == nil || _coreTextViewFlags.textChangesMade) {
			_coreTextViewFlags.textChangesMade = NO;
			[self processText];
		}
        
//        属性化字符串
		if (_processedString) {
			NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:_processedString];
			
			for (FTCoreTextNode * node in [_rootNode allSubnodes]) {
				[self applyStyle:node.style inRange:node.styleRange onString:&string];
			}
            [self setAttributedText:string];
//			[_attributedString release];
			_attributedString = string;
		}
	}
	return _attributedString;
}

- (void)setAttributedText:(NSMutableAttributedString *)attributedText
{
    //    _attributedText = attributedText;
    
    CTParagraphStyleSetting lineBreakMode;
    CTLineBreakMode lineBreak = kCTLineBreakByCharWrapping;
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
    
    CTParagraphStyleSetting settings[] = {
        lineBreakMode
    };
    CTParagraphStyleRef style = CTParagraphStyleCreate(settings, 1);
    
    // build attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:(__bridge id)style forKey:(id)kCTParagraphStyleAttributeName];
    CFRelease(style);
    // set attributes to attributed string
    [attributedText addAttributes:attributes range:NSMakeRange(0, attributedText.length)];
}

#pragma mark - View lifecycle

/*!
 * @abstract draw the actual coretext on the context
 *
 */

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	[self.backgroundColor setFill];
	CGContextFillRect(context, rect);
	
    [self updateFramesetterIfNeeded];
    CGMutablePathRef mainPath = CGPathCreateMutable();
    
    if (!_path) {
        CGPathAddRect(mainPath, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    }
    else {
        CGPathAddPath(mainPath, NULL, _path);
    }
    
    CTFrameRef drawFrame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), mainPath, NULL);
    
    if (drawFrame == NULL) {
//        infoLog(@"FTCoreText unable to render: %@", self.processedString);
    }
    else {
        //draw images
        if ([_images count] > 0) {
            [self drawImages];
        }
        
        if (_shadowColor) {
            CGContextSetShadowWithColor(context, _shadowOffset, 0.f, _shadowColor.CGColor);
        }
        
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, self.bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        // draw text
        CTFrameDraw(drawFrame, context);
    }
    // cleanup
    if (drawFrame)
        CFRelease(drawFrame);
    
    CGPathRelease(mainPath);
}

- (void)drawImages
{
	CGMutablePathRef mainPath = CGPathCreateMutable();
    if (!_path) {
        CGPathAddRect(mainPath, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    }
    else {
        CGPathAddPath(mainPath, NULL, _path);
    }
	
    CTFrameRef ctframe = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), mainPath, NULL);
    CGPathRelease(mainPath);
	
    NSArray *lines = (NSArray *)CTFrameGetLines(ctframe);
    NSInteger lineCount = [lines count];
    
    CGPoint origins[lineCount];
	CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), origins);//得到每行的起始位置
	
    NSInteger imageIndex = 0;
	FTCoreTextNode *imageNode = [_images objectAtIndex:imageIndex];
	for (int i = 0; i < lineCount; i++) {
		CGPoint baselineOrigin = origins[i];
		//the view is inverted, the y origin of the baseline is upside down
		baselineOrigin.y = CGRectGetHeight(self.frame) - baselineOrigin.y;
		CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
        for (id runObj in (NSArray *)CTLineGetGlyphRuns(line))
        {
//            NSLog(@"runCount %d",[((NSArray *)CTLineGetGlyphRuns(line)) count]);
            CTRunRef run = (__bridge CTRunRef)runObj;
            CFRange runRange = CTRunGetStringRange(run);//获取run在整段文字中的Range
            // if the image range locate in a CFRun
            if (runRange.location <= imageNode.styleRange.location &&
                runRange.location+ runRange.length > imageNode.styleRange.location)
            {
//                分段区域
                CGRect runBounds;
                CGFloat ascent, descent;
                runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
                runBounds.size.height = ascent + descent;
                CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);//计算CTRun与CTLine原点的距离。
                baselineOrigin.x = baselineOrigin.x<0?0:baselineOrigin.x;
                runBounds.origin.x = baselineOrigin.x + xOffset;
                runBounds.origin.y = baselineOrigin.y;
                runBounds.origin.y -= ascent;
                
                CGPathRef pathRef = CTFrameGetPath(ctframe);
                CGRect colRect = CGPathGetBoundingBox(pathRef);//得到占用的区域大小
                
//                获得图片绘制区域
                CGRect imgBounds = CGRectOffset(runBounds, colRect.origin.x, colRect.origin.y);//相对于源矩形原点（左上角的点）沿x轴和y轴偏移
                
                CTTextAlignment alignment = imageNode.style.textAlignment;
                
                UIImage *img = imageNode.image;
                if (img) {
//                    根据对齐方式,重新调整x轴
                    if (alignment == kCTRightTextAlignment)
//                        imgBounds.origin.x = (self.frame.size.width - img.size.width);
                        imgBounds.origin.x += (runBounds.size.width - img.size.width);
                    if (alignment == kCTCenterTextAlignment)
//                        imgBounds.origin.x = ((self.frame.size.width - img.size.width) / 2);
                        imgBounds.origin.x += ((runBounds.size.width - img.size.width) / 2);
                    
//                    重新调整大小
//                    imgBounds.size = img.size;
                    imgBounds.size = CGSizeMake(img.size.width/img.size.height *floor(runBounds.size.height), floor(runBounds.size.height));
                    
//                    根据insets重新调整x、y轴
                    // adjusting frame @TODO need more test
                    UIEdgeInsets insets = imageNode.style.paragraphInset;
                    if (alignment != kCTCenterTextAlignment) {
                        if (alignment == kCTLeftTextAlignment) {
                            imgBounds.origin.x += insets.left;
                        }
                        else {
                            imgBounds.origin.x += insets.left;
                        }
                    }
                    imgBounds.origin.y += insets.top;
                    if ((imgBounds.origin.y + imgBounds.size.height) < runBounds.size.height) {
                        imgBounds.origin.y += (runBounds.size.height - imgBounds.origin.y - imgBounds.size.height)/2;
                    }
                    if ((insets.left + insets.right + img.size.width ) > self.frame.size.width) {
                        imgBounds.size.width = self.frame.size.width;
                    }
                    
                    [img drawInRect:CGRectIntegral(imgBounds)];
                    imageNode.nodeBounds = imgBounds;
                }
                imageIndex ++;
                if (imageIndex >= [_images count]) {
                    break;
                }
                imageNode = [_images objectAtIndex:imageIndex];
            }
        }
	}
	CFRelease(ctframe);
}


#pragma mark User Interaction

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(coreTextView:receivedTouchOnData:)])
    {
        CGPoint point = [(UITouch *)[touches anyObject] locationInView:self];
        NSDictionary *data = [self dataForPoint:point];
        if (data && data.count > 0) {
            [self.delegate coreTextView:self receivedTouchOnData:data];
            // don't sent the message to supper if we had catch an event;
            return ;
        }
    }
    [super touchesEnded:touches withEvent:event];
}


- (NSArray*)linesWidth{
    CGMutablePathRef mainPath = CGPathCreateMutable();
    
    if (!_path) {
        CGPathAddRect(mainPath, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    }
    else {
        CGPathAddPath(mainPath, NULL, _path);
    }
    
    CTFrameRef drawFrame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), mainPath, NULL);
    NSArray *ret = [self textLineRects:drawFrame];
    if (drawFrame)
         CFRelease(drawFrame);
    if(mainPath)
        CFRelease(mainPath);
    return ret;
}
- (NSArray*)textLineRects:(CTFrameRef)frameRef{
    NSMutableArray * lineRects = nil ;
    if (frameRef) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, self.bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        
        NSArray * lines =(__bridge NSArray *) CTFrameGetLines(frameRef);
        for ( int i = 0 ; i < lines.count ; i++) {
            CTLineRef lineRef = (__bridge CTLineRef) lines[i];
            CGRect rect = CTLineGetBoundsWithOptions(lineRef, kCTLineBoundsExcludeTypographicLeading);
            if (lineRects == nil) {
                lineRects = [NSMutableArray new];
            }
            [lineRects addObject:NSStringFromCGRect(rect)];
        }
        
        UIGraphicsPopContext();
    }
    return lineRects ;
}

@end

@implementation NSString (FTCoreText)
- (NSString *)stringByAppendingTagName:(NSString *)tagName
{
	return [NSString stringWithFormat:@"[%@]%@[/%@]", tagName, self, tagName];
}
@end
