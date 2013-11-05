//
//  GPUImageAffineTransformFilter.m
//  GPUImage
//
//  Created by Martin Stämmler on 09.08.13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageAffineTransformFilter.h"


NSString *const kGPUImageAffineTransformationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp mat3 trafoMatrix; // nicht mehr lowp, sondern highp
 
 void main()
 {
     // Texturkoordinaten in homogenen Koordinaten
     highp vec3 textureCoordinateH = vec3(textureCoordinate.xy, 1.0);
     
     // Transformation anwenden
     /*
      highp vec3 textureCoordinateTransformedH = trafoMatrix * textureCoordinateH;  // TODO: b^T*A^T vs. A*b
      highp vec2 textureCoordinateTransformed = vec2(textureCoordinateTransformedH.x/textureCoordinateTransformedH.z, textureCoordinateTransformedH.y/textureCoordinateTransformedH.z);
      
      gl_FragColor = texture2D(inputImageTexture, textureCoordinateTransformed);
      */
     
     
     // zuvor
     highp vec3 textureCoordinateTransformedH = trafoMatrix * textureCoordinateH;  // TODO: b^T*A^T vs. A*b
     gl_FragColor = texture2D(inputImageTexture, textureCoordinateTransformedH.xy);
     
     
     // Koordinaten-Test
     //     highp vec3 textureCoordinateTransformedH = trafoMatrix * textureCoordinateH;  // TODO: b^T*A^T vs. A*b
     //     if (textureCoordinateH.y > 0.05) {
     //         gl_FragColor = vec4(1.0);
     //     } else {
     //         gl_FragColor = vec4(0.0);
     //     }
     //     gl_FragColor = texture2D(inputImageTexture, textureCoordinateTransformedH.xy/textureCoordinateTransfor
     
     
     
     
     //     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     //     lowp vec4 outputColor = textureColor * colorMatrix;
     
     //     gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
 }
 );

@implementation GPUImageAffineTransformFilter

@synthesize trafoMatrix = _trafoMatrix;
@synthesize relSize = _relSize;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageAffineTransformationFragmentShaderString]))
    {
        return nil;
    }
    
    projectiveTransformationMatrixUniform = [filterProgram uniformIndex:@"trafoMatrix"];
    
    self.trafoMatrix = (GPUMatrix3x3){
        {1.0f, 0.0f, 0.0f},
        {0.0f, 1.0f, 0.0f},
        {0.0f, 0.0f, 1.0f}
    };
    
    
    
    [self calculateCropTextureCoordinates];
    
    
    return self;
}

#pragma mark -
#pragma mark Accessors


- (void)setTrafoMatrix:(GPUMatrix3x3)newTrafoMatrix;
{
    _trafoMatrix = newTrafoMatrix;
    
    [self setMatrix3f:_trafoMatrix forUniform:projectiveTransformationMatrixUniform program:filterProgram];
}

- (void)setRelSize:(CGSize)relSizeNeu {
    _relSize = relSizeNeu;
    [self calculateCropTextureCoordinates];
}



#pragma mark -
#pragma mark Rendering

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    //    NSLog(@"setInputSize (%f, %f) at index %d", newSize.width, newSize.height, textureIndex);
    
    if (self.preventRendering)
    {
        return;
    }
    
    //    if (overrideInputSize)
    //    {
    //        if (CGSizeEqualToSize(forcedMaximumSize, CGSizeZero))
    //        {
    //            return;
    //        }
    //        else
    //        {
    //            CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(newSize, CGRectMake(0.0, 0.0, forcedMaximumSize.width, forcedMaximumSize.height));
    //            inputTextureSize = insetRect.size;
    //            return;
    //        }
    //    }
    
    CGSize rotatedSize = [self rotatedSize:newSize forIndex:textureIndex];
    //    originallySuppliedInputSize = rotatedSize;
    
    //    NSLog(@"originallySuppliedInputSize = (%f, %f)", originallySuppliedInputSize.width, originallySuppliedInputSize.height);
    
    CGSize scaledSize;
    //    scaledSize.width = rotatedSize.width * _cropRegion.size.width;
    //    scaledSize.height = rotatedSize.height * _cropRegion.size.height;
    scaledSize.width = rotatedSize.width * _relSize.width;
    scaledSize.height = rotatedSize.height * _relSize.height;
    
    scaledSize.width = roundf(scaledSize.width); // testweise rein
    scaledSize.height = roundf(scaledSize.height);
    
    if (CGSizeEqualToSize(scaledSize, CGSizeZero))
    {
        inputTextureSize = scaledSize;
    }
    else if (!CGSizeEqualToSize(inputTextureSize, scaledSize))
    {
        inputTextureSize = scaledSize;
        [self recreateFilterFBO];
    }
    
    //    NSLog(@"inputTextureSize = (%f, %f)", inputTextureSize.width, inputTextureSize.height);
    
}


- (void)calculateCropTextureCoordinates;
{
    //    CGFloat minX = _cropRegion.origin.x;
    //    CGFloat minY = _cropRegion.origin.y;
    //    CGFloat maxX = CGRectGetMaxX(_cropRegion);
    //    CGFloat maxY = CGRectGetMaxY(_cropRegion);
    CGFloat minX = 0;
    CGFloat minY = 0;
    CGFloat maxX = _relSize.width;
    CGFloat maxY = _relSize.height;
    
    switch(inputRotation)
    {
        case kGPUImageNoRotation: // Works
        {
            cropTextureCoordinates[0] = minX; // 0,0
            cropTextureCoordinates[1] = minY;
            
            cropTextureCoordinates[2] = maxX; // 1,0
            cropTextureCoordinates[3] = minY;
            
            cropTextureCoordinates[4] = minX; // 0,1
            cropTextureCoordinates[5] = maxY;
            
            cropTextureCoordinates[6] = maxX; // 1,1
            cropTextureCoordinates[7] = maxY;
        }; break;
        case kGPUImageRotateLeft: // Broken
        {
            cropTextureCoordinates[0] = maxX; // 1,0
            cropTextureCoordinates[1] = minY;
            
            cropTextureCoordinates[2] = maxX; // 1,1
            cropTextureCoordinates[3] = maxY;
            
            cropTextureCoordinates[4] = minX; // 0,0
            cropTextureCoordinates[5] = minY;
            
            cropTextureCoordinates[6] = minX; // 0,1
            cropTextureCoordinates[7] = maxY;
        }; break;
        case kGPUImageRotateRight: // Fixed
        {
            cropTextureCoordinates[0] = minY; // 0,1
            cropTextureCoordinates[1] = 1.0 - minX;
            
            cropTextureCoordinates[2] = minY; // 0,0
            cropTextureCoordinates[3] = 1.0 - maxX;
            
            cropTextureCoordinates[4] = maxY; // 1,1
            cropTextureCoordinates[5] = 1.0 - minX;
            
            cropTextureCoordinates[6] = maxY; // 1,0
            cropTextureCoordinates[7] = 1.0 - maxX;
        }; break;
        case kGPUImageFlipVertical: // Broken
        {
            cropTextureCoordinates[0] = minX; // 0,1
            cropTextureCoordinates[1] = maxY;
            
            cropTextureCoordinates[2] = maxX; // 1,1
            cropTextureCoordinates[3] = maxY;
            
            cropTextureCoordinates[4] = minX; // 0,0
            cropTextureCoordinates[5] = minY;
            
            cropTextureCoordinates[6] = maxX; // 1,0
            cropTextureCoordinates[7] = minY;
        }; break;
        case kGPUImageFlipHorizonal: // Broken
        {
            cropTextureCoordinates[0] = maxX; // 1,0
            cropTextureCoordinates[1] = minY;
            
            cropTextureCoordinates[2] = minX; // 0,0
            cropTextureCoordinates[3] = minY;
            
            cropTextureCoordinates[4] = maxX; // 1,1
            cropTextureCoordinates[5] = maxY;
            
            cropTextureCoordinates[6] = minX; // 0,1
            cropTextureCoordinates[7] = maxY;
        }; break;
        case kGPUImageRotate180: // Broken
        {
            cropTextureCoordinates[0] = maxX; // 1,1
            cropTextureCoordinates[1] = maxY;
            
            cropTextureCoordinates[2] = maxX; // 1,0
            cropTextureCoordinates[3] = minY;
            
            cropTextureCoordinates[4] = minX; // 0,1
            cropTextureCoordinates[5] = maxY;
            
            cropTextureCoordinates[6] = minX; // 0,0
            cropTextureCoordinates[7] = minY;
        }; break;
        case kGPUImageRotateRightFlipVertical: // Fixed
        {
            cropTextureCoordinates[0] = minY; // 0,0
            cropTextureCoordinates[1] = 1.0 - maxX;
            
            cropTextureCoordinates[2] = minY; // 0,1
            cropTextureCoordinates[3] = 1.0 - minX;
            
            cropTextureCoordinates[4] = maxY; // 1,0
            cropTextureCoordinates[5] = 1.0 - maxX;
            
            cropTextureCoordinates[6] = maxY; // 1,1
            cropTextureCoordinates[7] = 1.0 - minX;
        }; break;
    }
    
    
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    static const GLfloat cropSquareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    [self renderToTextureWithVertices:cropSquareVertices textureCoordinates:cropTextureCoordinates sourceTexture:filterSourceTexture];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}


@end