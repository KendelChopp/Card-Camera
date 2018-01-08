//
//  OpenCVWrapper.h
//  Card Camera
//
//  Created by Kendel Chopp on 1/7/18.
//  Copyright © 2018 Kendel Chopp. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif
//@class UIViewController;

@interface CardCameraWrapper : NSObject
-(id)initWithController:(UIViewController*)c andImageView:(UIImageView*)iv withNumCards:(int)numCards;
-(void) loadTrainingNumber: (UIImage *)image;
-(void) loadTrainingSuit: (UIImage *)image;
-(void)start;
-(void)stop;
-(NSString *)identifyCard;
@end
