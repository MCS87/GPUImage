//
//  GPUImageProjectiveTransformationFilter.h
//  GPUImage
//
//  Created by Martin Stämmler on 06.08.13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageProjectiveTransformationFilter : GPUImageFilter {
    GLint projectiveTransformationMatrixUniform;
    GLfloat cropTextureCoordinates[8];
    CGSize relSize;
}

@property(readwrite, nonatomic) GPUMatrix3x3 trafoMatrix;

@property(readwrite, nonatomic) CGSize relSize;



@end
