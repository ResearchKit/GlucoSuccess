// 
//  APHSliderCellView.m 
//  GlucoSuccess 
// 
// Copyright (c) 2015, Massachusetts General Hospital. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 
 
#import "APHSliderCellView.h"

static CGFloat kTextFontSize = 15.0f;
static CGFloat kDetailFontSize = 14.0f;

@interface APHSliderCellView()



@end

@implementation APHSliderCellView

- (void)sharedInit
{
    _elementIndex = 0;
    _textValue = nil;
    _detailText = nil;
    _isCurrent = NO;
    _isAvailable = YES;
    _selectedBarHeight = 3;
    _unavailableColor = [UIColor lightGrayColor];
    _backgroundColor = [UIColor whiteColor];
    _currentColor = [UIColor colorWithRed:0.094 green:0.439 blue:0.980 alpha:1.000];
    _selectedColor = [UIColor colorWithRed:0.992 green:0.506 blue:0.039 alpha:1.000];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self sharedInit];
    }
    
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self sharedInit];
    }
    
    return self;
}

#pragma mark - Accessors

- (void)setTextValue:(NSString *)textValue
{
    _textValue = textValue;
    
    [self setNeedsDisplay];
}

- (void)setIsCurrent:(BOOL)isCurrent
{
    _isCurrent = isCurrent;
    
    [self setNeedsDisplay];
}

- (void)setIsAvailable:(BOOL)isAvailable
{
    _isAvailable = isAvailable;
    
    [self setNeedsDisplay];
}

#pragma mark - Touches

- (void)touchesEnded:(NSSet *) __unused touches withEvent:(UIEvent *) __unused event
{
    if (self.isAvailable == NO) {
        if ([self.delegate respondsToSelector:@selector(didSelectUnavailableCell:elementIndex:)]) {
            [self.delegate didSelectUnavailableCell:self.cellKind elementIndex:self.elementIndex];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didSelectCell:elementIndex:)]) {
            [self.delegate didSelectCell:self.cellKind elementIndex:self.elementIndex];
        }
    }
}


#pragma mark - Draw Rect

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat borderWidth = 1.0;
    CGFloat currentBorderWidth = 3.0;
    UIColor *borderColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1.000];
    
    // Background
    UIColor *bgColor = self.backgroundColor;
    [bgColor setFill];
    UIRectFill(rect);
    
    // Top border
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, borderWidth);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, rect.size.width, 0);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    // Bottom border
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    
    if (self.isCurrent) {
        CGContextSetStrokeColorWithColor(context, self.currentColor.CGColor);
        CGContextSetLineWidth(context, currentBorderWidth);
    } else {
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, borderWidth);
    }
    
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    
    UIColor *foregroundColor = [UIColor blackColor];
    
    if (self.isCurrent == YES) {
        foregroundColor = self.currentColor;
    } else if (self.isAvailable == NO) {
        foregroundColor = self.unavailableColor;
    }
    
    // text value
    NSDictionary *attr = @{
                           NSFontAttributeName: [UIFont systemFontOfSize:kTextFontSize],
                           NSParagraphStyleAttributeName: style,
                           NSBackgroundColorAttributeName: [UIColor whiteColor],
                           NSForegroundColorAttributeName: foregroundColor
                           };
    
    CGFloat verticalAlignment;
    
    if (!self.detailText) {
        verticalAlignment = (CGRectGetMidY(rect) - (21/2));
    } else {
        verticalAlignment = (CGRectGetMidY(rect) - 21);
    }
    
    CGRect stringRect = CGRectMake(0, verticalAlignment, rect.size.width, 21);
    
    [self.textValue drawInRect:stringRect
                withAttributes:attr];
    
    // detail text
    NSDictionary *attrDetailText = @{
                                       NSFontAttributeName: [UIFont systemFontOfSize:kDetailFontSize],
                                       NSParagraphStyleAttributeName: style,
                                       NSBackgroundColorAttributeName: [UIColor whiteColor],
                                       NSForegroundColorAttributeName: foregroundColor
                                    };
    
    CGFloat verticalAlignmentToTextValue = stringRect.size.height + 10;
    CGRect detailStringRect = CGRectMake(0, verticalAlignmentToTextValue, rect.size.width, 21);
    
    [self.detailText drawInRect:detailStringRect
                 withAttributes:attrDetailText];
}

@end
