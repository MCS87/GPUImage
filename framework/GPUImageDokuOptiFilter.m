//
//  GPUImageDokuOptiFilter.m
//  GPUImage
//
//  Created by Martin Stämmler on 09.08.13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageDokuOptiFilter.h"

NSString *const kGPUImageDokuOptiFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform mediump float filterOffset; // zuvor lowp
 
 void main()
 {
     // zuvor beides lowp
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate); // doku
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2); // blurdoku

//     blurDoku[k] = (doku[k] - filterOffset)/(blurDoku[k] - filterOffset);
     
     
  
     // bisherige Variante (letzte Version)
     
//     gl_FragColor = vec4((textureColor.rgb - vec3(filterOffset))/(textureColor2.rgb - vec3(filterOffset)), 1.0);
     
     
     
     // Alternative 1
     
//     gl_FragColor = mix(textureColor, vec4((textureColor.rgb - vec3(filterOffset))/(textureColor2.rgb - vec3(filterOffset)), 1.0),1.5); // 2.0 ziemlich krass, hintergrund total weiss, schrift etwas zu blass
     
     
     // Alternative 2
     // zvuor 0.15, 1.25
     // jetzt 0.2, 1.25
     
     // zu heftig; 0.15 1.25
     
     // 0.15 1.25 App Store
     // testweise zuletzt 0.1

     mediump float myOffset = 0.15; // _0.25_
     mediump float weight = 1.25;
     weight = 1.1;
     
     
     // 0.25 1.25   es wird zu viel weggefressen
     // 0.2 1.25    es wird zu vile weggefressen (bei Serifen, z.B. E-ON)
     
     
     // 0.1 1.0     schwächerer Kontrast, leichtes weißes Rauschen, keine bunte Stelle
     // 0.1 1.25    schwächerer Kontrast, kaum weißes Rauschen
     // 0.1 1.5     schwächerer Kontrast, "angefressen", kein Rauschen
     // 0.1 2.0     schwächerer Kontrast, noch mehr angefressen
     // 0.1 5.0     noch extremer
     
     
     // 0.2 1.0     etwas schwacher Kontrast, kaum Rauschen
     // 0.2 1.25    !!! Kontrast OK, kein Rauschen
     // 0.2 1.5     Kontrast OK, etwas zu blass, kein Rauschen
     
     // 0.25 1.25   !!!!
     
     
     // 0.3 1.0     Kontrast gut, leichtes Rauschen
     // 0.3 1.25    ! Kontrast gut, kein Rauschen
     // 0.3 1.5     !! Kontrast gut, ganz bisschen blass
     
     
     // 0.5 1.0     kontrastreich, viele bunte Stellen, starkes buntes Rauschen
     // 0.5 1.25    dazwischen
     // 0.5 1.5     kontrastreich, viele bunte Stellen, leichtes buntes Rauschen
     // 0.5 2.0     extremer
     // 0.5 5.0     noch extremer, keine Grautöne
     
     
//     highp vec3 resColor = mix(textureColor.rgb, vec3((textureColor.rgb - vec3(myOffset))/(textureColor2.rgb - vec3(myOffset))),weight);
//     resColor.r = min(max(resColor.r, 0.0), 1.0);
//     resColor.g = min(max(resColor.g, 0.0), 1.0);
//     resColor.b = min(max(resColor.b, 0.0), 1.0);
     
//     gl_FragColor = vec4(resColor,1.0); // 2.0 ziemlich krass, hintergrund total weiss, schrift etwas zu blass
     
     
     // alt
//     gl_FragColor = mix(textureColor, vec4((textureColor.rgb - vec3(myOffset))/(textureColor2.rgb - vec3(myOffset)), 1.0),weight); // 2.0 ziemlich krass, hintergrund total weiss, schrift etwas zu blass
     

     // zähler und nenner clampen
//     gl_FragColor = mix(textureColor, vec4(clamp((textureColor.rgb - vec3(myOffset)),0.0,1.0)/clamp((textureColor2.rgb - vec3(myOffset)), 0.08, 1.0), 1.0),weight);
     
     gl_FragColor = mix(textureColor, vec4((textureColor.rgb - vec3(myOffset))/clamp((textureColor2.rgb - vec3(myOffset)), 0.15, 1.0), 1.0),weight); // 0.08..1.0; 0.33..1.0

     //     gl_FragColor = mix(textureColor, vec4((textureColor.rgb)/(textureColor2.rgb), 1.0),1.5); // total blass
     
     
     
     
     
     
//     gl_FragColor = mix(textureColor, textureColor2, mixturePercent);
 }
 );

@implementation GPUImageDokuOptiFilter

@synthesize offset = _offset;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageDokuOptiFragmentShaderString]))
    {
		return nil;
    }
    
    offsetUniform = [filterProgram uniformIndex:@"filterOffset"];
    self.offset = 0.1;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setOffset:(CGFloat)newValue;
{
    _offset = newValue;
    
    [self setFloat:_offset forUniform:offsetUniform program:filterProgram];
}

@end

