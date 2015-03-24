//
//  ResponsiveLabel.m
//  ResponsiveLabel
//
//  Created by hsusmita on 13/03/15.
//  Copyright (c) 2015 hsusmita.com. All rights reserved.
//

#import "ResponsiveLabel.h"
#import "TouchGestureRecognizer.h"

@interface ResponsiveLabel ()<NSLayoutManagerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *searchStrings;
@property (nonatomic, retain) NSLayoutManager *layoutManager;
@property (nonatomic, retain) NSTextContainer *textContainer;
@property (nonatomic, retain) NSTextStorage *textStorage;

@property (nonatomic, strong) UIColor *selectedLinkBackgroundColor;
@property (nonatomic, assign) NSRange selectedRange;
@property (nonatomic, assign) BOOL isTouchMoved;

@end
@implementation ResponsiveLabel

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
      [self setupTextSystem];
      [self configureForGestures];
      }
    return self;
  }

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupTextSystem];
    [self configureForGestures];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  // Update our container size when the view frame changes
  self.textContainer.size = self.bounds.size;
}

#pragma mark - Custom Getters

- (NSTextStorage *)textStorage {
  if (!_textStorage) {
    _textStorage = [[NSTextStorage alloc] init];
    [_textStorage addLayoutManager:self.layoutManager];
    [self.layoutManager setTextStorage:_textStorage];
  }
  
  return _textStorage;
}

- (NSTextContainer *)textContainer {
  if (!_textContainer) {
    _textContainer = [[NSTextContainer alloc] init];
    _textContainer.lineFragmentPadding = 0;
    _textContainer.maximumNumberOfLines = self.numberOfLines;
    _textContainer.lineBreakMode = self.lineBreakMode;
    _textContainer.widthTracksTextView = YES;
    _textContainer.size = self.frame.size;
    
    [_textContainer setLayoutManager:self.layoutManager];
  }
  
  return _textContainer;
}

- (NSLayoutManager *)layoutManager {
  if (!_layoutManager) {
    // Create a layout manager for rendering
    _layoutManager = [[NSLayoutManager alloc] init];
    _layoutManager.delegate = self;
    [_layoutManager addTextContainer:self.textContainer];
  }
  
  return _layoutManager;
}

#pragma mark - Custom Setters

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  
  CGSize size = frame.size;
  size.width = MIN(size.width, self.preferredMaxLayoutWidth);
  size.height = 0;
  self.textContainer.size = size;
}

- (void)setBounds:(CGRect)bounds {
  [super setBounds:bounds];
  
  CGSize size = bounds.size;
  size.width = MIN(size.width, self.preferredMaxLayoutWidth);
  size.height = 0;
  self.textContainer.size = size;
}

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
  [super setPreferredMaxLayoutWidth:preferredMaxLayoutWidth];
  
  CGSize size = self.bounds.size;
  size.width = MIN(size.width, self.preferredMaxLayoutWidth);
  self.textContainer.size = size;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
  [super setAttributedText:attributedText];
  [self.textStorage setAttributedString:attributedText];
}

- (void)setText:(NSString *)text {
  [super setText:text];
  [self.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:text]];
}

#pragma mark - Drawing

- (void)drawTextInRect:(CGRect)rect {
  // Don't call super implementation. Might want to uncomment this out when
  // debugging layout and rendering problems.
  // [super drawTextInRect:rect];
  
  // Calculate the offset of the text in the view
  CGPoint textOffset;
  NSRange glyphRange = [_layoutManager glyphRangeForTextContainer:_textContainer];
  textOffset = [self calcTextOffsetForGlyphRange:glyphRange];
  
  // Drawing code
  [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textOffset];
  [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:textOffset];
}

- (CGPoint)calcTextOffsetForGlyphRange:(NSRange)glyphRange {
  CGPoint textOffset = CGPointZero;
  
  CGRect textBounds = [_layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:_textContainer];
  CGFloat paddingHeight = (self.bounds.size.height - textBounds.size.height) / 2.0f;
  if (paddingHeight > 0)
    textOffset.y = paddingHeight;
  
  return textOffset;
}

- (void)setupTextSystem
{
  // Create a text container and set it up to match our label properties
//  _textContainer = [[NSTextContainer alloc] init];
  _textContainer.lineFragmentPadding = 0;
  _textContainer.maximumNumberOfLines = self.numberOfLines;
  _textContainer.lineBreakMode = self.lineBreakMode;
  _textContainer.size = self.frame.size;
  
  // Create a layout manager for rendering
//  _layoutManager = [[NSLayoutManager alloc] init];
  _layoutManager.delegate = self;
  [_layoutManager addTextContainer:_textContainer];
  
  // Attach the layou manager to the container and storage
  [_textContainer setLayoutManager:_layoutManager];
  
  // Make sure user interaction is enabled so we can accept touches
  self.userInteractionEnabled = YES;
  
//  // Don't go via public setter as this will have undesired side effect
//  _automaticLinkDetectionEnabled = YES;
//  
//  // All links are detectable by default
//  _linkDetectionTypes = KILinkTypeAll;
//  
//  // Link Type Attributes. Default is empty (no attributes).
//  _linkTypeAttributes = [NSMutableDictionary dictionary];
//  
//  // Don't underline URL links by default.
//  _systemURLStyle = NO;
  
  self.selectedLinkBackgroundColor = nil;//[UIColor colorWithWhite:0.95 alpha:1.0];
  
  // Establish the text store with our current text
  [self updateTextStoreWithText];
}

- (void)updateTextStoreWithText
{
  // Now update our storage from either the attributedString or the plain text
  if (self.attributedText)
    [self updateTextStoreWithAttributedString:self.attributedText];
  else if (self.text)
    [self updateTextStoreWithAttributedString:[[NSAttributedString alloc] initWithString:self.text attributes:[self attributesFromProperties]]];
  else
    [self updateTextStoreWithAttributedString:[[NSAttributedString alloc] initWithString:@"" attributes:[self attributesFromProperties]]];
  
  [self setNeedsDisplay];
}

- (void)updateTextStoreWithAttributedString:(NSAttributedString *)attributedString
{
 /* if (attributedString.length != 0)
    {
    attributedString = [KILabel sanitizeAttributedString:attributedString];
    }
  
  if (self.isAutomaticLinkDetectionEnabled && (attributedString.length != 0))
    {
//    self.linkRanges = [self getRangesForLinks:attributedString];
//    attributedString = [self addLinkAttributesToAttributedString:attributedString linkRanges:self.linkRanges];
    }
  else
    {
    self.linkRanges = nil;
    }
  */
  if (_textStorage)
    {
    // Set the string on the storage
    [_textStorage setAttributedString:attributedString];
    }
  else
    {
    // Create a new text storage and attach it correctly to the layout manager
    _textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
    [_textStorage addLayoutManager:_layoutManager];
    [_layoutManager setTextStorage:_textStorage];
    }
}

- (NSDictionary *)attributesFromProperties
{
  // Setup shadow attributes
  NSShadow *shadow = shadow = [[NSShadow alloc] init];
  if (self.shadowColor)
    {
    shadow.shadowColor = self.shadowColor;
    shadow.shadowOffset = self.shadowOffset;
    }
  else
    {
    shadow.shadowOffset = CGSizeMake(0, -1);
    shadow.shadowColor = nil;
    }
  
  // Setup colour attributes
  UIColor *colour = self.textColor;
  if (!self.isEnabled)
    colour = [UIColor lightGrayColor];
  else if (self.isHighlighted)
    colour = self.highlightedTextColor;
  
  // Setup paragraph attributes
  NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
  paragraph.alignment = self.textAlignment;
  
  // Create the dictionary
  NSDictionary *attributes = @{NSFontAttributeName : self.font,
                               NSForegroundColorAttributeName : colour,
                               NSShadowAttributeName : shadow,
                               NSParagraphStyleAttributeName : paragraph,
                               };
  return attributes;
}

#pragma mark - Override UILabel Methods

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
  // Use our text container to calculate the bounds required. First save our
  // current text container setup
  CGSize savedTextContainerSize = self.textContainer.size;
  NSInteger savedTextContainerNumberOfLines = self.textContainer.maximumNumberOfLines;
  
  // Apply the new potential bounds and number of lines
  self.textContainer.size = bounds.size;
  self.textContainer.maximumNumberOfLines = numberOfLines;
  
  // Measure the text with the new state
  CGRect textBounds;
  @try
  {
  NSRange glyphRange = [self.layoutManager
                        glyphRangeForTextContainer:self.textContainer];
  textBounds = [self.layoutManager boundingRectForGlyphRange:glyphRange
                                             inTextContainer:self.textContainer];
  
  // Position the bounds and round up the size for good measure
  textBounds.origin = bounds.origin;
  textBounds.size.width = ceilf(textBounds.size.width);
  textBounds.size.height = ceilf(textBounds.size.height);
  }
  @finally
  {
  // Restore the old container state before we exit under any circumstances
  self.textContainer.size = savedTextContainerSize;
  self.textContainer.maximumNumberOfLines = savedTextContainerNumberOfLines;
  }
  
  return textBounds;
}

#pragma mark - Touch Handlers

- (void)configureForGestures {
  // Make sure user interaction is enabled so we can accept touches
  self.userInteractionEnabled = YES;
  
  // Default background colour looks good on a white background
  self.selectedLinkBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
  
  // Attach a default detection handler to help with debugging
//  self.linkTapHandler = ^(NSURL *URL) {
//    NSLog(@"Default handler for %@", URL);
//  };
  
  TouchGestureRecognizer *touch = [[TouchGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleTouch:)];
  touch.delegate = self;
  [self addGestureRecognizer:touch];
}

- (void)handleTouch:(UIGestureRecognizer *)gesture {
  NSLog(@"tap on text");
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
  CGPoint touchLocation = [touch locationInView:self];
  
  NSInteger index = [self stringIndexAtLocation:touchLocation];
  
  NSRange effectiveRange;
  NSURL *touchedURL = nil;
  
  if (index != NSNotFound)
    {
     touchedURL = [self.attributedText attribute:NSLinkAttributeName atIndex:index effectiveRange:&effectiveRange];
    }
  
  if (touchedURL)
    {
    return YES;
    }
  
  return NO;
}


- (NSUInteger)stringIndexAtLocation:(CGPoint)location {
  // Do nothing if we have no text
  if (self.textStorage.string.length == 0)
    {
    return NSNotFound;
    }
  
  // Work out the offset of the text in the view
  CGPoint textOffset;
  NSRange glyphRange = [self.layoutManager
                        glyphRangeForTextContainer:self.textContainer];
  textOffset = [self calcTextOffsetForGlyphRange:glyphRange];
  
  // Get the touch location and use text offset to convert to text cotainer coords
  location.x -= textOffset.x;
  location.y -= textOffset.y;
  
  NSUInteger glyphIndex = [self.layoutManager glyphIndexForPoint:location
                                                 inTextContainer:self.textContainer];
  
  // If the touch is in white space after the last glyph on the line we don't
  // count it as a hit on the text
  NSRange lineRange;
  CGRect lineRect = [self.layoutManager lineFragmentUsedRectForGlyphAtIndex:glyphIndex
                                                             effectiveRange:&lineRange];
  
  if (!CGRectContainsPoint(lineRect, location))
    {
    return NSNotFound;
    }
  
  return [self.layoutManager characterIndexForGlyphAtIndex:glyphIndex];
}


+ (BOOL)requiresConstraintBasedLayout {
  return YES;
}

@end
