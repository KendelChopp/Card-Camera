# Personal Intro to Computer Vision

## Introduction

This Winter Break I tasked myself with learning a little something about computer vision. In order to learn, I decided I was going to create an iOS application that can read standard playing cards. The system is by no means perfect, but I have learned a lot and I will discuss what I have done, how it works, and where I might go with it in the future. My goal is to also make this less technical so that people without CS backgrounds can read this, but if you are interested in the actual code I wrote, it is available on Github. 

## Locating the Card(s)

Before starting I made a few key assumptions:
1) These are standard playing cards
2) The cards are on a dark background
3) And for this post, we are only looking for one card (but it can be scaled to search for more with a few changes)

All that being said, let's begin. First, we need a picture of the card we want to identify. For this I will be using a picture I took of the 9 of clubs.

<img alt="Full size card" width="100px" src="http://kchopp.com/card_img/original.png">

Now that we have this image, we need to be able to find the edges of the card. In order to do this, first we make it black and white (grayscale) and we apply a Gaussian blur to try and remove the noise. This picture is relatively clear so the blur has little effect.

<img alt="Gray card" width="100px" src="http://kchopp.com/card_img/gray.png">

Now that we have reduced the image to a range of grays, we can now use a threshold to make every pixel either black or white. If a pixel is bright enough it will be white, and if not, the pixel will be black. This is called a binary threshold because each pixel is either black or white (1 or 0). 

<img alt="Threshold card" width="100px" src="http://kchopp.com/card_img/binary.png">

So we now have this thresholded picture, and to the human eye it is now very clear where the card is. The white space and everything contained within it represents the card. In order to find the edges of the card we locate the contours. Contours are the lines (curves) that goes along boundaries of pixels with the same color (More about contours \[1\]). In this case, the largest contour will be the outline of the card. Additionally, in order to speed up the process, the method to find the contours will only look for the corners, so the edge is not perfectly outlined. Finally, this image isn’t actually used, it is just a visual representation of what a contour is.

<img alt="Contours" width="100px" src="http://kchopp.com/card_img/contour.png">

This next part is one of the more complicated parts. When we have a picture of this card, the card could be tilted, the angle skewed, varying width/height (in pixels), etc. Due to this variation, we need to get the picture into a standard format. For this, I decided to make every card into a 200x300 image. So, how do we get just the card to fit into a 200x300 frame? Well, it is by using a perspective transformation. On a basic level what happens is we take the 4 corners of the original image, then we force those 4 corners to fit in the frame. Then we force the pixels within the 4 corners to translate in the same way so that the picture remains the same and is now all within the frame. For more information on the actual math behind this transformation refer to \[2\] and \[3\]. So, after this transformation we are left with this image.

<img alt="Warped Card" width="100px" src="http://kchopp.com/card_img/warpedCard.png">

Woohoo! Now we have a picture of just the card. Now you may say just check if this image is equal to some store 9 of clubs image, but this is problematic because the perspective transformation is not perfect, and other factors such as lighting and the orientation of the card can affect the image, and that leads into the next part. 

## Identifying the Card(s)

How do we combat the possibility of variation in the images? I chose to do so by reading the top left corner of the card, which means we have to crop the picture to be just the corner.

<img alt="Corner cropped" width="50px" src="http://kchopp.com/card_img/cornerCropped.png">

Now that we have the corner, we have to identify the suit and number. First, we will crop out each. We will threshold the image so we do not have to worry about any grayscale issues.

<img alt="Corner thresholded" width="50px" src="http://kchopp.com/card_img/cornerThreshold.png">

Now that it is thresholded, we remove all of the black edges by narrowing the picture down to the most extreme white pixels.

<img alt="Corner bounded" width="50px" src="http://kchopp.com/card_img/finalCorner.png">

Next, although the image is not always perfect, it is consistent enough where 25 pixels above the bottom of the corner lands between the number and the suit. That means we can now locate the suit by taking the 25 lowest pixels.

<img alt="Suit" width="50px" src="http://kchopp.com/card_img/suit.png">

The 25 pixels includes some padding on top as one can see, so we again remove the black edges again.

<img alt="Suit bounded" width="50px" src="http://kchopp.com/card_img/suitBounded.png">

This is excellent as we now have an image that just contains the suit. In order to figure out what suit it is we compare it to our reference images, and see how many pixels they have in common. The comparison makes a pixel white if the 2 images have the same value (either both black or both white) and makes it black if one is white and the other is black. Here are the results from this image.

| Suit | Generated Image |
| ------------- | ------------- |
| Spades  | <img alt="Spades Comparison" src="http://kchopp.com/card_img/spadeComp.png">  |
| Hearts  | <img alt="Spades Comparison" src="http://kchopp.com/card_img/heartComp.png">  |
| Diamonds  | <img alt="Spades Comparison" src="http://kchopp.com/card_img/diamondComp.png">  |
| Clubs  | <img alt="Spades Comparison" src="http://kchopp.com/card_img/clubComp.png">  |

As you can see, the club has the most white (least black) so it is in fact a club. One can also see why this may not be perfect, though, because the spade is relatively close too. So although we can not be certain, our best guess is that the card is in fact the clubs suit which, in this case, is correct. The exact same technique is applied to the number (or letter in the case of aces and face cards).

## Outcomes

It works! Not perfectly, but with relatively high accuracy from my initial testing. I did what I wanted, but there are definitely optimizations to be made. One potential optimization is to check for the card color, and that can eliminate two of the suits. Another issue I have is that it really isn’t that fast. When doing all of this real-time my iPhone 6 can not handle it as it is reduced to roughly 15 FPS which is less than ideal. I am currently trying to find ways to speed it up such as maybe messing with the sizes of the images to decrease the number of calculations. This speed is such a challenge because the phone has such a high quality camera that there are so many pixels to deal with. For an initial run though, I am satisfied with the results. Hopefully I will be able to make some optimizations that can speed it up and maybe potentially allow for real-time analysis. Currently the iOS application only is setup for the single card mode, but I hope to add more in the near future! Please also check out the references and my Github project if you want to divulge more into it. 

\[1\] https://docs.opencv.org/3.3.1/d4/d73/tutorial_py_contours_begin.html

\[2\] https://docs.opencv.org/2.4/modules/imgproc/doc/geometric_transformations.html#getperspectivetransform

\[3\] https://docs.opencv.org/2.4/modules/imgproc/doc/geometric_transformations.html#warpperspective

\[4\] https://en.wikipedia.org/wiki/Gaussian_blur

\[5\] http://arnab.org/blog/so-i-suck-24-automating-card-games-using-opencv-and-python

\[6\] https://opencv.org/
