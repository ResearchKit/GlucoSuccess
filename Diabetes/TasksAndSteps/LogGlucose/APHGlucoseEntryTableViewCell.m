// 
//  APHGlucoseEntryTableViewCell.m 
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
 
#import "APHGlucoseEntryTableViewCell.h"

@import APCAppCore;

NSString *const kGlucoseNotMeasured = @"Not Measured";

@interface APHGlucoseEntryTableViewCell()

@property (nonatomic, weak) IBOutlet UILabel *mealTimeLabel;
@property (nonatomic, weak) IBOutlet UITextField *glucoseReadingTextField;
@property (nonatomic, weak) IBOutlet UILabel *glucoseReadingUnitLabel;
@property (nonatomic, weak) IBOutlet UILabel *notMeasuredLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textFieldTrailingConstraint;

@property (nonatomic, getter=isNotMeassured) BOOL notMeasured;

@end

@implementation APHGlucoseEntryTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.glucoseReadingUnitLabel.hidden = YES;
    
    self.notMeasuredLabel.text = NSLocalizedString(kGlucoseNotMeasured, nil);
    self.notMeasuredLabel.hidden = YES;
    
    [self configureInputAccessoryViewForTextField:self.glucoseReadingTextField];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        if (self.notMeasuredLabel.isHidden == NO) {
            self.notMeasuredLabel.hidden = YES;
            self.glucoseReadingTextField.hidden = NO;
        }
        [self.glucoseReadingTextField becomeFirstResponder];
        self.glucoseReadingUnitLabel.hidden = NO;
        
        self.mealTimeLabel.textColor = [UIColor appPrimaryColor];
    } else {
        self.mealTimeLabel.textColor = [UIColor blackColor];
        
        if (self.glucoseReadingTextField.text.length > 0 && self.notMeasuredLabel.isHidden) {
            self.glucoseReadingUnitLabel.hidden = NO;
        } else {
            self.glucoseReadingUnitLabel.hidden = YES;
        }
        
        [self.glucoseReadingTextField resignFirstResponder];
    }
}

- (void)setCaptionMealTime:(NSString *)captionMealTime
{
    _captionMealTime = captionMealTime;
    
    self.mealTimeLabel.text = captionMealTime;
}

- (void)setGlucoseReading:(NSNumber *)glucoseReading
{
    _glucoseReading = glucoseReading;
    
    if (glucoseReading) {
        if ([glucoseReading isEqualToNumber:@(NSNotFound)]) {
            [self handleNotMeasured:nil];
        } else {
            self.glucoseReadingTextField.text = [NSString stringWithFormat:@"%lu", [glucoseReading integerValue]];
            self.glucoseReadingUnitLabel.hidden = NO;
        }
    } else {
        self.glucoseReadingTextField.text = nil;
        self.glucoseReadingUnitLabel.hidden = YES;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.glucoseReadingTextField.enabled = editing;
    
    if (!editing) {
        [self.glucoseReadingTextField resignFirstResponder];
    }
}

- (void)setTextFieldTag:(NSInteger)textFieldTag
{
    _textFieldTag = textFieldTag;
    
    self.glucoseReadingTextField.tag = textFieldTag;
}

- (BOOL)isNotMeasured
{
    return _notMeasured;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat borderWidth = 0.25;
    
    UIColor *borderColor = [UIColor appBorderLineColor];
    
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
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, borderWidth);
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)configureInputAccessoryViewForTextField:(UITextField *)textField
{
    UIToolbar *notMeasuredToolbar = [[UIToolbar alloc] init];
    [notMeasuredToolbar sizeToFit];
    
    UIBarButtonItem *btnNotMeasured = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(kGlucoseNotMeasured, nil)
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self action:@selector(handleNotMeasured:)];
    
    UIBarButtonItem *flexbileSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    UIBarButtonItem *btnSubmit = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(handleSubmit:)];
    
    notMeasuredToolbar.items = @[btnNotMeasured, flexbileSpace, btnSubmit];
    
    textField.inputAccessoryView = notMeasuredToolbar;
    
}

- (void)handleNotMeasured:(UIBarButtonItem *) __unused sender
{
    self.glucoseReadingUnitLabel.hidden = YES;
    self.glucoseReadingTextField.text = nil;
    self.glucoseReadingTextField.hidden = YES;
    self.notMeasuredLabel.hidden = NO;
    
    self.notMeasured = YES;
    
    [self.glucoseReadingTextField resignFirstResponder];
    
    if ([self.delegate respondsToSelector:@selector(didSelectNotMeasured)]) {
        [self.delegate didSelectNotMeasured];
    }
}

- (void)handleDone:(UIBarButtonItem *) __unused sender
{
    [self.glucoseReadingTextField resignFirstResponder];
    [self setSelected:NO animated:YES];
}

- (void)handleSubmit:(UIBarButtonItem *) __unused sender
{
    [self handleDone:nil];
    
    if ([self.delegate respondsToSelector:@selector(didSubmitReading)]) {
        [self.delegate didSubmitReading];
    }
}

@end
