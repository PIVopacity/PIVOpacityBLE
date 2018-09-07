/*
 Copyright (c) 2018 United States Government
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */


#import "MyButtons.h"

@implementation MyButtons

#pragma mark -
#pragma mark Custom Rounded Rect Buttons

+ (UIButton *)buttonWithTitle:(NSString *)title
					   target:(id)target
					 selector:(SEL)selector
						frame:(CGRect)frame
				   buttonSize:(int)buttonSize
						image:(UIImage *)image
				 imagePressed:(UIImage *)imagePressed
				 overlayImage:(UIImage *)overlayImage
		  overlayImagePressed:(UIImage *)overlayImagePressed
					 darkText:(BOOL)darkText
					  revText:(BOOL)revText
				darkTextColor:(UIColor *)darkTextColor
				 revTextColor:(UIColor *)revTextColor
					 boldText:(BOOL)boldText
					 fontSize:(CGFloat)fontSize
                       radius:(CGFloat)radius
{	
	UIButton *button = [[UIButton alloc] initWithFrame:frame];
	
	//Set up button title with text and font
	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	
	if(boldText)
		button.titleLabel.font = [UIFont boldSystemFontOfSize: fontSize];
	else
		button.titleLabel.font = [UIFont systemFontOfSize: fontSize];
	
	[button setTitle:title forState:UIControlStateNormal];	
	if (darkText)
	{
		[button setTitleColor:darkTextColor forState:UIControlStateNormal];
		if (revText)
			[button setTitleColor:revTextColor forState:UIControlStateHighlighted];
	}
	else
	{
		[button setTitleColor:revTextColor forState:UIControlStateNormal];
		if (revText)
			[button setTitleColor:darkTextColor forState:UIControlStateHighlighted];
	}
	
	//Set up images for button
	float topCapHeight = 0.0;
	float leftCapHeight = 12.0;
	
	//Default buttons if no button image specified
	UIImage *defaultImageLargeButton = [UIImage imageNamed: @"whiteButton.png"];
	UIImage *defaultImageLargeButtonPressed = [UIImage imageNamed: @"blueButton.png"];
	
	UIImage *defaultImageSmallButton = [UIImage imageNamed: @"smallbuttonwhite.png"];
	UIImage *defaultImageSmallButtonPressed = [UIImage imageNamed: @"smallbuttonblue.png"];

	if(image == nil)
		switch (buttonSize) {
			case 1:
				image = defaultImageSmallButton;
				break;
			case 2:
				image = defaultImageLargeButton;
				break;
			default:
				break;
		}
	
	if(imagePressed == nil)
		switch (buttonSize) {
			case 1:
				imagePressed = defaultImageSmallButtonPressed;
				break;
			case 2:
				imagePressed = defaultImageLargeButtonPressed;
				break;
			default:
				break;
		}
	
	UIImage *newImage = [image stretchableImageWithLeftCapWidth:leftCapHeight topCapHeight:topCapHeight];
	[button setImage:overlayImage forState:UIControlStateNormal];
	[button setBackgroundImage:newImage forState:UIControlStateNormal];
	
	UIImage *newPressedImage = [imagePressed stretchableImageWithLeftCapWidth:leftCapHeight topCapHeight:topCapHeight];
	if (overlayImagePressed != nil) {
		[button setImage:overlayImagePressed forState:UIControlStateHighlighted];
	}
	[button setBackgroundImage:newPressedImage forState:UIControlStateHighlighted];
	
	[button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
	
	button.backgroundColor = [UIColor clearColor];
    
    if (radius > 0) {
        button.clipsToBounds = YES;
        button.layer.cornerRadius = radius;
    }
	return button;
}

@end
