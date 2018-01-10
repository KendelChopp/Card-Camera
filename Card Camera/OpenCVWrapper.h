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
#import <opencv2/imgcodecs/ios.h>
#endif
//@class UIViewController;

@interface CameraFunctions : NSObject
extern int const CARD_MIN_AREA;
extern int const CORNER_WIDTH;
extern int const CORNER_HEIGHT;
extern int const SUIT_HEIGHT;
extern int const MIN_THRESH;
+(void) loadTrainingNumber: (UIImage *)image;
+(void) loadTrainingSuit: (UIImage *)image;
#ifdef __cplusplus
+(cv::Rect) getCornerBounded:(cv::Mat)corner;
+(cv::Mat) warpCard:(cv::Mat)originalImage withPoints:(cv::Point2f[4])points withWidth:(int)width withHeight:(int)height;
+(cv::Mat) preprocess_cardCorner:(cv::Mat)contour andSourceImage:(cv::Mat)sourceImage;
+(cv::Mat) preprocess_video:(cv::Mat)input;
+(std::vector<cv::Mat>) findCardContours:(cv::Mat)preprocessedImage withNumCards:(int)totalCards;
#endif
@end

@interface CardCameraWrapper : NSObject
{
    int totalCards;
    int currentCard;
    int prevCard;
    #ifdef __cplusplus
    cv::Mat currentImage;
    #endif
}
#ifdef __cplusplus
-(void) drawContours:(cv::Mat)image;
#endif
-(id)initWithController:(UIViewController*)c andImageView:(UIImageView*)iv withNumCards:(int)numCards;
-(void)start;
-(void)stop;
-(NSString *)identifyCard;
@end


@interface SingleCardCamera : CardCameraWrapper

@end
@interface SingleCardLiveCamera : CardCameraWrapper
-(void) setupLive:(UILabel *)label;
@end
