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
//The comparison methods for sorting countours from largest -> smallest
bool compareContourAreas ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 )
{
    double i = fabs( contourArea(cv::Mat(contour1)) );
    double j = fabs( contourArea(cv::Mat(contour2)) );
    return ( i > j );
}
bool compareLocations ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 )
{
    double i = contour1[0].x;
    double j = contour2[0].x;
    return ( i > j );
}
vector<cv::Mat> numbers;
vector<cv::Mat> suits;

@interface GolfCamera()
{
}
@end
@implementation GolfCamera
{
    bool hasBlock;
}
//Processese the images by drawing the contour lines
- (void)processImage:(Mat&)image
{
    image.copyTo(currentImage);
    (void) [self drawContours:image];
}

-(int)getScore
{
    cv::Mat modifiedImage;
    prevCard = currentCard;
    modifiedImage = [CameraFunctions preprocess_video:currentImage];
    int values[6];
    vector<cv::Mat> cards = [CameraFunctions findCardContours:modifiedImage withNumCards:totalCards];
    if (cards.size() != 6) {
        currentCard = -1;
        return -15;
    }
    std::sort(cards.begin(),cards.end(), compareLocations);
    for (int i = 0; i < 6; i++) {
        cv::Mat card = [CameraFunctions preprocess_cardCorner:cards[i] andSourceImage:currentImage];
        //card = [CardCameraWrapper getSuit:card];
        cv::Rect bounds = [CameraFunctions getCornerBounded:card];
        if (bounds.height <= 10) {
            currentCard = -1;
            return -15;
        }
        if (bounds.height > 21) {
            cv::Rect newFrame = cv::Rect(0,bounds.height - 20 , card.cols, card.rows - (bounds.height - 20));
            
            card(newFrame).copyTo(card);
            bounds = [CameraFunctions getCornerBounded:card];
        }
        cv::Mat finalCorner;
        card(bounds).copyTo(finalCorner);

        cv::Mat tempResult;
        int score;
        int maxIndex = -1;
        int maxValue = MIN_THRESH;

        cv::Mat numberArea;
        cv::Rect numberFrame = cv::Rect(0,0,finalCorner.cols - SUIT_HEIGHT - 1, finalCorner.rows);
        finalCorner(numberFrame).copyTo(numberArea);
        cv::Mat numberNonZero;
        findNonZero(numberArea, numberNonZero);
        numberArea(boundingRect(numberNonZero)).copyTo(numberArea);
        resize(numberArea,numberArea, cv::Size(62,34));

        for (int i = 0; i < numbers.size(); i++) {
            cv::compare(numberArea, numbers.at(i), tempResult, cv::CMP_EQ);
            score = countNonZero(tempResult);
            if (score > maxValue) {
                maxIndex = i;
                maxValue = score;
            }
        }
        currentCard = currentCard + maxIndex;

        if (maxIndex == -1) {
            return -15;
        } else if (maxIndex >= 0 && maxIndex <= 9) {
            values[i] = maxIndex + 1;
        } else if (maxIndex == 10 || maxIndex == 11) {
            values[i] = 10;
        } else if (maxIndex == 12) {
            values[i] = 0;
        } else if (maxIndex == 13) {
            values[i] = -2;
        }
        
    }

    return [self scoreArray:values];
}
-(bool)getBlock
{
    return hasBlock;
}
-(int)scoreArray: (int[6])cardValues
{
    int blockFlag = false;
    int score = 0;
    cout << "Values: [";
    for (int i = 0; i < 3; i++) {
        if (cardValues[i*2] == cardValues[i*2+1]) {
            if (cardValues[i*2] == -2) {
                score -= 4;
            }
            if (i < 2) {
                if (cardValues[i*2] == cardValues[i*2+2] && cardValues[i*2] == cardValues[i*2+3]) {
                    blockFlag = true;
                }
            }
        } else {
            score += cardValues[i*2] + cardValues[i*2+1];
        }
        cout << " " << cardValues[i];
    }
    cout << "]\n";
    hasBlock = blockFlag;
    return score;
}
@end

@interface SingleCardLiveCamera()
{
}
@end
@implementation SingleCardLiveCamera
{
    UILabel * cardLabel;
    int count;
}

-(void) setupLive:(UILabel *)label
{
    cardLabel = label;
    count = 0;
}
//Processese the images by drawing the contour lines
- (void)processImage:(Mat&)image
{
    image.copyTo(currentImage);
    if (count >= 4) {
        @try {
            NSString *cardString = [self identifyCard];
            if (currentCard != prevCard) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cardLabel.text = cardString;
                });
            }
        }
        @catch(...) {
            cout << "ERROR!\n";
        }
        count = 0;
    } else count++;
    //(void) [self drawContours:image];
}

@end


@interface SingleCardCamera()
{
}
@end
@implementation SingleCardCamera
{
    
}
//Processese the images by drawing the contour lines
- (void)processImage:(Mat&)image
{
    image.copyTo(currentImage);
    (void) [self drawContours:image];
}

@end


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
    prevCard = currentCard;
    modifiedImage = [CameraFunctions preprocess_video:currentImage];
    
    vector<cv::Mat> cards = [CameraFunctions findCardContours:modifiedImage withNumCards:totalCards];
    if (cards.size() < 1) {
        currentCard = -1;
        return @"NO CARD FOUND";
    }
    cv::Mat card = [CameraFunctions preprocess_cardCorner:cards[0] andSourceImage:currentImage];
    //card = [CardCameraWrapper getSuit:card];
    cv::Rect bounds = [CameraFunctions getCornerBounded:card];
    if (bounds.height <= 10) {
        currentCard = -1;
        return @"NO CARD FOUND";
    }
    
    if (bounds.height > 21) {
        cv::Rect newFrame = cv::Rect(0,bounds.height - 20 , card.cols, card.rows - (bounds.height - 20));
        
        card(newFrame).copyTo(card);
        bounds = [CameraFunctions getCornerBounded:card];
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
    int maxValue = MIN_THRESH;
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
    
    currentCard = 13*maxIndex;
    maxIndex = -1;
    maxValue = MIN_THRESH;
    for (int i = 0; i < numbers.size(); i++) {
        cv::compare(numberArea, numbers.at(i), tempResult, cv::CMP_EQ);
        score = countNonZero(tempResult);
        if (score > maxValue) {
            maxIndex = i;
            maxValue = score;
        }
    }
    currentCard = currentCard + maxIndex;
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
        currentCard = 52;
    }
   
    NSString *cardString = [number stringByAppendingString:@" "];
    cardString = [cardString stringByAppendingString:suit];
    if (maxIndex == 13) {
        cardString = number;
    }
    return cardString;
}

-(void) drawContours:(cv::Mat)image {
    vector<cv::Mat>  contours;
    //vector<vector<cv::Point>>  hierarchy;
    cv::Mat im = [CameraFunctions preprocess_video:image];
    cv::findContours(im, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
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

- (void)processImage:(Mat&)image
{
  
    
}

@end

@interface CameraFunctions()
{
}
@end
@implementation CameraFunctions
{
    
}
int const CARD_MIN_AREA = 6000;
int const CORNER_WIDTH = 26;
int const CORNER_HEIGHT = 80;
int const SUIT_HEIGHT = 25;
int const MIN_THRESH = 0;

//Load in the reference number images
+(void) loadTrainingNumber: (UIImage *)image
{
    if (numbers.size() > 14) return;
    cv::Mat trainingImage;
    UIImageToMat(image, trainingImage);
    numbers.push_back(trainingImage);
}
//Load in the reference suit images
+(void) loadTrainingSuit: (UIImage *)image
{
    if (suits.size() > 14) return;
    cv::Mat trainingImage;
    UIImageToMat(image, trainingImage);
    suits.push_back(trainingImage);
}
//Returns a vector of suspected cards found in a preprocessed image
+(vector<cv::Mat>) findCardContours:(cv::Mat)preprocessedImage withNumCards:(int)totalCards {
    vector<cv::Mat>  contours;
    cv::findContours(preprocessedImage, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
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
//Returns a thresholded version of the input
+(cv::Mat) preprocess_video:(cv::Mat)input
{
    cv::Mat modify;
    cvtColor(input, modify, CV_BGR2GRAY);
    cv::GaussianBlur(modify, modify, cvSize(5,5),0);
    cv::threshold(modify, modify, 120, 255, CV_THRESH_BINARY);
    return modify;
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
    cv::Mat warpedCard = [CameraFunctions warpCard:sourceImage withPoints:pts withWidth:rect.width withHeight:rect.height];
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
+(cv::Rect) getCornerBounded:(cv::Mat)corner
{
    cv::Mat points;
    findNonZero(corner, points);
    cv::Rect minRect;
    minRect = boundingRect(points);
    return minRect;
}
@end
