//
//  OpenCVWrapper.m
//  Card Camera
//
//  Created by Kendel Chopp on 1/7/18.
//  Copyright © 2018 Kendel Chopp. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"
#import <AVFoundation/AVFoundation.h>
#import <opencv2/videoio/cap_ios.h>
using namespace std;
using namespace cv;



@interface CardCameraWrapper () <CvVideoCameraDelegate>
{
}
@end

@implementation CardCameraWrapper
{
    UIViewController * viewController;
    UIImageView * imageView;
    CvVideoCamera * videoCamera;
    //UILabel * cardLabel;
    int currentCard;
    int totalCards;
    cv::Mat currentImage;
    vector<cv::Mat> numbers;
    vector<cv::Mat> suits;
}


static int CARD_MIN_AREA = 6000;
static int CORNER_WIDTH = 26;
static int CORNER_HEIGHT = 80;
static int SUIT_HEIGHT = 25;
static int minThresh = 0;

//The comparison methods for sorting countours from largest -> smallest
bool compareContourAreas ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 )
{
    double i = fabs( contourArea(cv::Mat(contour1)) );
    double j = fabs( contourArea(cv::Mat(contour2)) );
    return ( i > j );
}

//Load in the reference number images
-(void) loadTrainingNumber: (UIImage *)image
{
    cv::Mat trainingImage;
    UIImageToMat(image, trainingImage);
    numbers.push_back(trainingImage);
}
//Load in the reference suit images
-(void) loadTrainingSuit: (UIImage *)image
{
    cv::Mat trainingImage;
    UIImageToMat(image, trainingImage);
    suits.push_back(trainingImage);
}
//Camera initializer
-(id)initWithController:(UIViewController*)c andImageView:(UIImageView*)iv withNumCards:(int)numCards
{
    viewController = c;
    imageView = iv;
    currentCard = -1;
    totalCards = numCards;
    videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    videoCamera.delegate = self;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.rotateVideo = YES;
    videoCamera.defaultFPS = 30;
    videoCamera.grayscaleMode = NO;
    return self;
}
-(void)start
{
    (void)[videoCamera start];
}
-(void)stop
{
    (void)[videoCamera stop];
}
//Method called that identifies the card in the image
- (NSString *)identifyCard
{
    cv::Mat modifiedImage;
    
    modifiedImage = [CardCameraWrapper preprocess_video:currentImage];
    
    vector<cv::Mat> cards = [self findCardContours:modifiedImage];
    if (cards.size() < 1) {
        return @"NO CARD FOUND";
    }
    cv::Mat card = [CardCameraWrapper preprocess_cardCorner:cards[0] andSourceImage:currentImage];
    //card = [CardCameraWrapper getSuit:card];
    cv::Rect bounds = [CardCameraWrapper getCornerBounded:card];
    if (bounds.height <= 10) {
        return @"NO CARD FOUND";
    }
    
    if (bounds.height > 21) {
        cv::Rect newFrame = cv::Rect(0,bounds.height - 20 , card.cols, card.rows - (bounds.height - 20));

        card(newFrame).copyTo(card);
        bounds = [CardCameraWrapper getCornerBounded:card];
    }
    cv::Mat finalCorner;
    card(bounds).copyTo(finalCorner);
    cv::Mat suitArea;
    cv::Rect suitFrame = cv::Rect(finalCorner.cols - SUIT_HEIGHT,0, SUIT_HEIGHT, finalCorner.rows);
    finalCorner(suitFrame).copyTo(suitArea);
    cv::Mat suitNonZero;
    findNonZero(suitArea, suitNonZero);
    suitArea(boundingRect(suitNonZero)).copyTo(suitArea);
    resize(suitArea, suitArea, cv::Size(38,34));
    NSString *suit;
    cv::Mat tempResult;
    int score;
    int maxIndex = -1;
    int maxValue = minThresh;
    for (int i = 0; i < suits.size(); i++) {
        cv::compare(suitArea, suits.at(i), tempResult, cv::CMP_EQ);
        score = countNonZero(tempResult);
        if (score > maxValue) {
            maxIndex = i;
            maxValue = score;
        }
    }
    if (maxIndex == -1) {
        suit = @"UNKNOWN";
    } else if (maxIndex == 0) {
        suit = @"SPADES";
    } else if (maxIndex == 1) {
        suit = @"HEARTS";
    } else if (maxIndex == 2) {
        suit = @"DIAMONDS";
    } else if (maxIndex == 3) {
        suit = @"CLUBS";
    }
    
    cv::Mat numberArea;
    cv::Rect numberFrame = cv::Rect(0,0,finalCorner.cols - SUIT_HEIGHT - 1, finalCorner.rows);
    finalCorner(numberFrame).copyTo(numberArea);
    cv::Mat numberNonZero;
    findNonZero(numberArea, numberNonZero);
    numberArea(boundingRect(numberNonZero)).copyTo(numberArea);
    resize(numberArea,numberArea, cv::Size(62,34));

    maxIndex = -1;
    maxValue = minThresh;
    for (int i = 0; i < numbers.size(); i++) {
        cv::compare(numberArea, numbers.at(i), tempResult, cv::CMP_EQ);
        score = countNonZero(tempResult);
        if (score > maxValue) {
            maxIndex = i;
            maxValue = score;
        }
    }
    NSString *number;
    if (maxIndex == -1) {
        number = @"UNKNOWN";
    } else if (maxIndex >= 1 && maxIndex <= 9) {
        number = @(maxIndex + 1).stringValue;
    } else if (maxIndex == 0) {
        number = @"A";
    } else if (maxIndex == 10) {
        number = @"J";
    } else if (maxIndex == 11) {
        number = @"Q";
    } else if (maxIndex == 12) {
        number = @"K";
    } else if (maxIndex == 13) {
        number = @"JOKER";
    }
    NSString *cardString = [number stringByAppendingString:@" "];
    cardString = [cardString stringByAppendingString:suit];
    if (maxIndex == 13) {
        cardString = number;
    }
    return cardString;
}
//Processese the images by drawing the contour lines
- (void)processImage:(Mat&)image
{
    image.copyTo(currentImage);
    vector<cv::Mat>  contours;
    //vector<vector<cv::Point>>  hierarchy;
    cv::Mat im = [CardCameraWrapper preprocess_video:image];
    cv::findContours(im, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
    std::sort(contours.begin(), contours.end(), compareContourAreas);
    vector<cv::Mat>  cards;
    int numFoundCards = 0;
    for (int i = 0; i < contours.size(); i++) {
        if (numFoundCards >= totalCards) break;
        double area = contourArea(contours[i]);
        if (area < CARD_MIN_AREA) break;
        double arcLength = cv::arcLength(contours[i], true);
        cv::Mat approx;
        approxPolyDP(contours[i], approx, 0.01*arcLength, true);
        if (approx.rows == 4) {
            numFoundCards++;
            for (int i = 0; i < 3; i++) {
                cv::line(image, cv::Point(approx.at<int>(i, 0), approx.at<int>(i, 1)),
                         cv::Point(approx.at<int>(i+1, 0), approx.at<int>(i+1, 1)), cv::Scalar(0,255,0, 255), 25);
                
            }
            cv::line(image, cv::Point(approx.at<int>(3, 0), approx.at<int>(3, 1)),
                     cv::Point(approx.at<int>(0, 0), approx.at<int>(0, 1)), cv::Scalar(0,255,0, 255), 25);
        }
    }
    
}

//Returns a thresholded version of the input
+(cv::Mat) preprocess_video:(cv::Mat)input
{
    cv::Mat modify;
    cvtColor(input, modify, CV_BGR2GRAY);
    cv::GaussianBlur(modify, modify, cvSize(5,5),0);
    //Improvement may be made by changing the threshold level depending on the light level
    cv::threshold(modify, modify, 120, 255, CV_THRESH_BINARY);
    return modify;
}
//Returns a vector of suspected cards found in a preprocessed image
-(vector<cv::Mat>) findCardContours:(cv::Mat)preprocessedImage {
    vector<cv::Mat>  contours;
    cv::findContours(preprocessedImage, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
    std::sort(contours.begin(), contours.end(), compareContourAreas);
    vector<cv::Mat>  cards;
    int numFound = 0;
    for (int i = 0; i < contours.size(); i++) {
        if (numFound >= totalCards) break;
        double area = contourArea(contours[i]);
        if (area < CARD_MIN_AREA) break;
        double arcLength = cv::arcLength(contours[i], true);
        cv::Mat approx;
        approxPolyDP(contours[i], approx, 0.01*arcLength, true);
        if (approx.rows == 4) {
            numFound++;
            cards.push_back(contours[i]);
        }
    }
    return cards;
}
//Crop to the corner of the card and threshold it
+(cv::Mat) preprocess_cardCorner:(cv::Mat)contour andSourceImage:(cv::Mat)sourceImage
{
    double perimeter = cv::arcLength(contour, true);
    cv::Mat approx;
    approxPolyDP(contour, approx, 0.01*perimeter, true);
    cv::Rect rect;
    rect = boundingRect(contour);
    cv::Point2f pts[4];
    pts[0] = cv::Point(approx.at<int>(0, 0), approx.at<int>(0, 1));
    pts[1] = cv::Point(approx.at<int>(1, 0), approx.at<int>(1, 1));
    pts[2] = cv::Point(approx.at<int>(2, 0), approx.at<int>(2, 1));
    pts[3] = cv::Point(approx.at<int>(3, 0), approx.at<int>(3, 1));
    cv::Mat warpedCard = [CardCameraWrapper warpCard:sourceImage withPoints:pts withWidth:rect.width withHeight:rect.height];
    cv::Rect crop = cv::Rect(0,warpedCard.rows - 1 - CORNER_WIDTH, CORNER_HEIGHT, CORNER_WIDTH);
    cv::Mat corner;
    warpedCard(crop).copyTo(corner);
    cv::threshold(corner, corner, 120, 255, CV_THRESH_BINARY_INV);
    return corner;
}
//Do a perspective transformation to get a flattened 200x300 image of the card
+(cv::Mat) warpCard:(cv::Mat)originalImage withPoints:(cv::Point2f[4])points withWidth:(int)width withHeight:(int)height
{
    cv::Point2f src_vertices[4];
    cv::Point center = cv::Point((points[0].x + points[2].x) / 2, (points[0].y + points[2].y) / 2);
    if (width <= 0.8*height) {
        if (points[0].x < center.x) {
            src_vertices[0] = points[3];
            src_vertices[1] = points[0];
            src_vertices[2] = points[1];
            src_vertices[3] = points[2];
        } else {
            src_vertices[0] = points[0];
            src_vertices[1] = points[1];
            src_vertices[2] = points[2];
            src_vertices[3] = points[3];
        }
    } else if (width >= 1.2*height) {
        if (points[0].x < center.x) {
            src_vertices[0] = points[2];
            src_vertices[1] = points[3];
            src_vertices[2] = points[0];
            src_vertices[3] = points[1];
        } else {
            src_vertices[0] = points[1];
            src_vertices[1] = points[2];
            src_vertices[2] = points[3];
            src_vertices[3] = points[0];
        }
    } else {
        if (points[0].x > points[2].x) {
            if (points[1].y > points[3].y) {
                src_vertices[0] = points[3];
                src_vertices[1] = points[0];
                src_vertices[2] = points[1];
                src_vertices[3] = points[2];
            } else {
                src_vertices[0] = points[2];
                src_vertices[1] = points[3];
                src_vertices[2] = points[0];
                src_vertices[3] = points[1];
            }
        } else {
            if (points[1].y > points[3].y) {
                src_vertices[0] = points[1];
                src_vertices[1] = points[2];
                src_vertices[2] = points[3];
                src_vertices[3] = points[0];
            } else {
                src_vertices[0] = points[0];
                src_vertices[1] = points[1];
                src_vertices[2] = points[2];
                src_vertices[3] = points[3];
            }
        }
    }
    //BL->TL->TR->BR
    cv::Point2f dst_vertices[4];
    dst_vertices[0] = cv::Point(0, 0);
    dst_vertices[1] = cv::Point(0, 199);
    dst_vertices[2] = cv::Point(299, 199);
    dst_vertices[3] = cv::Point(299, 0);
    cv::Mat warpPerspectiveMatrix = cv::getPerspectiveTransform(src_vertices, dst_vertices);
    cv::Mat card;
    cv::warpPerspective(originalImage, card, warpPerspectiveMatrix, cv::Size(300,200));
    cvtColor(card, card, CV_BGR2GRAY);
    return card;
}
//Bound the corner to the white pixels only
+(cv::Rect) getCornerBounded:(cv::Mat)corner {
    cv::Mat points;
    findNonZero(corner, points);
    cv::Rect minRect;
    minRect = boundingRect(points);
    return minRect;
}
@end
