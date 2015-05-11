//
//  GameScene.m
//  BreakUp
//
//  Created by Apple on 4/27/15.
//  Copyright (c) 2015 Randall Lee. All rights reserved.
//

#import "GameScene.h"
#import "Utilites.h"

#import "BallNode.h"
#import "FlipperNode.h"
#import "BrickNode.h"

#import "DrainNode.h"
#import "WallNode.h"
#import "FlipperGuardNode.h"
#import "HUDNode.h"

#import "TapToStartNode.h"
#import "GameOverNode.h"

#import <AVFoundation/AVFoundation.h>

@interface GameScene ()

@property (nonatomic)TapToStartNode *tapToStart;
@property (nonatomic)BallNode *ball;
@property (nonatomic)FlipperNode *rightFlipper;
@property (nonatomic)FlipperNode *leftFlipper;

@property (nonatomic) CGSize screenSize;

// Time
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) NSTimeInterval timeSinceBrickAdded;
@property (nonatomic) NSTimeInterval totalGameTime;
@property (nonatomic) NSTimeInterval addBrickTimeInterval;

// Sounds
@property (nonatomic) AVAudioPlayer *backgroundMusic;
@property (nonatomic) AVAudioPlayer *gameOverMusic;

@property (nonatomic) BOOL gameOver;
@property (nonatomic) BOOL gameOverDisplayed;
@property (nonatomic) BOOL leftFlipperActive;
@property (nonatomic) BOOL rightFlipperActive;

@end

@implementation GameScene
{
    SKNode *world;
}

- (void)didMoveToView:(SKView *)view
{
    // Game mechanics setup
    self.lastUpdateTimeInterval = 0;
    self.timeSinceBrickAdded = 0;
    self.totalGameTime = 0;
    self.addBrickTimeInterval = 20.0;
    self.leftFlipperActive = NO;
    self.rightFlipperActive = NO;
    self.gameOver = NO;
    self.screenSize = [[UIScreen mainScreen] bounds].size;
    
    SKShader *pattern = [SKShader shaderWithSource:@""];
    
    /* Setup your scene here */
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"background_test"];
    background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    
    // Some sort of scene...
    world = [SKNode node];
    [self addChild:world];
    
    // Setup physics
    self.physicsWorld.gravity = CGVectorMake(0, -7.8); // -9.8
    self.physicsWorld.contactDelegate = self;
    
    // Add ball
    self.ball = [BallNode ballAtPosition:CGPointMake(CGRectGetMidX(self.frame), 100)];
    
    // Add flippers
    self.leftFlipper = [FlipperNode leftFlipperAtPosition:CGPointMake(CGRectGetMidX(self.frame)-175, 80)];
    self.rightFlipper = [FlipperNode rightFlipperAtPosition:CGPointMake(self.leftFlipper.position.x+348,
                                                                        self.leftFlipper.position.y)];
    
    // Add Drain/Ground
    DrainNode *drain = [DrainNode drainWithSize:CGSizeMake(self.frame.size.width, 5)];
    
    // Add Walls
    WallNode *wallLeft = [WallNode wallAtPosition:CGPointMake(CGRectGetMinX(self.frame)-10, 300)];
    WallNode *wallRight = [WallNode wallAtPosition:CGPointMake(CGRectGetMaxX(self.frame)+10, 300)];
    
    // Add taptostart label
    self.tapToStart = [TapToStartNode tapToStartAtPosition:CGPointMake(self.size.width / 2, 280)];
    
    // Add score HUD
    HUDNode *hud = [HUDNode hudAtPosition:CGPointMake(0, self.frame.size.height-40) inFrame:self.frame];
    
    [world addChild:self.ball];
    [world addChild:self.tapToStart];
    [world addChild:background];
    [world addChild:wallLeft];
    [world addChild:wallRight];
    [world addChild:self.leftFlipper];
    [world addChild:self.rightFlipper];
    [world addChild:drain];
    [world addChild:hud];
    
//    if (self.ball.position.y > self.leftFlipper.position.y)
//    {
//        self.ball.physicsBody.restitution = 1.0;
//    }
    
    [self setupSounds];
    
#pragma mark - Size Classes
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
//        CGSize result = [[UIScreen mainScreen] bounds].size;
        // iPhone 5/5s/5c
        if (self.screenSize.height == 568)
        {
            [self.leftFlipper removeFromParent];
            [self.rightFlipper removeFromParent];
            self.leftFlipper = [FlipperNode leftFlipperAtPosition:CGPointMake(CGRectGetMidX(self.frame)-170, 80)];
            self.rightFlipper = [FlipperNode rightFlipperAtPosition:CGPointMake(self.leftFlipper.position.x+338,
                                                                                self.leftFlipper.position.y)];
            
            [world addChild:self.leftFlipper];
            [world addChild:self.rightFlipper];
        }
        // iPhone 6
        else if (self.screenSize.height == 667)
        {

        }
        // iPhone 6+
        else if (self.screenSize.height == 736)
        {
            FlipperGuardNode *leftGuard = [FlipperGuardNode leftFlipperGuardAtPosition:CGPointMake(self.leftFlipper.position.x-15,
                                                                                                   self.leftFlipper.position.y+4)];
            FlipperGuardNode *rightGuard = [FlipperGuardNode rightFlipperGuardAtPosition:CGPointMake(self.rightFlipper.position.x+15,
                                                                                                     self.rightFlipper.position.y+4)];
            [world addChild:leftGuard];
            [world addChild:rightGuard];
        }
    }
}

#pragma mark - Contact and Touchs

- (void)didBeginContact:(SKPhysicsContact *)contact
{
//    NSLog(@"Contact!");
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    // Velocity from flipper flip
    if (firstBody.categoryBitMask == CollisionCategoryBall &&
        secondBody.categoryBitMask == CollisionCategoryFlipperLeft)
    {
        if (self.leftFlipperActive)
        {
//            NSLog(@"Left Flip<");
            [self.ball.physicsBody applyImpulse:CGVectorMake(5.0, ApplyFlipperVelocity)];
        }
    }
    if (firstBody.categoryBitMask == CollisionCategoryBall &&
        secondBody.categoryBitMask == CollisionCategoryFlipperRight)
    {
        if (self.rightFlipperActive)
        {
//            NSLog(@"Right Flip>");
            [self.ball.physicsBody applyImpulse:CGVectorMake(-5.0, ApplyFlipperVelocity)];
        }
    }
    // Game restart on Ball/Drain Contact
    if (firstBody.categoryBitMask == CollisionCategoryBall &&
        secondBody.categoryBitMask == CollisionCategoryDrain)
    {
        NSLog(@"BALL/DRAIN contact");
//        self.gameOver = YES;
        [self loseLife];
        
        // Moves the ball after a *life is lost
        if (!self.gameOver)
        {
            SKAction *moveBall = [SKAction moveTo:CGPointMake(CGRectGetMaxX(self.frame)+[Utilites randomWithMin:-50.0 max:-15.0], CGRectGetMidY(self.frame)) duration:0.1];
            [self.ball runAction:moveBall];
        }
    }
    // Game restart on Brick/Drain Contact
    if (firstBody.categoryBitMask == CollisionCategoryDrain &&
        secondBody.categoryBitMask == CollisionCategoryBrick)
    {
        BrickNode *brick = (BrickNode *)secondBody.node;
        NSLog(@"Bricks have drained");
        
        // Remove points per brick
        if (!self.gameOver)
        {
            [self addPoints:-100];
        }
        [brick removeFromParent];
        
        
    }
    // Brick Contact Logic and Brick scoring
    if (firstBody.categoryBitMask == CollisionCategoryBall &&
        secondBody.categoryBitMask == CollisionCategoryBrick)
    {
        NSLog(@"POW!");
        BrickNode *brick = (BrickNode *)secondBody.node;
//        BallNode *ball = (BallNode *)secondBody.node;
        if (!self.gameOver)
        {
            [self addPoints:25];
            
            // blue double hit brick
            if ([brick isDamaged] &&
                brick.type == BrickTypeA)
            {
                [brick removeFromParent];
                [self addPoints:150];
                [self explosionAtPosition:contact.contactPoint];
            }
            // red single hit brick
            if (brick.type == BrickTypeB)
            {
                [brick removeFromParent];
                [self addPoints:100];
                [self explosionAtPosition:contact.contactPoint];
            }
        }
        
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if (self.gameOver)
    {
        for (SKNode *node in [self children])
        {
            [node removeFromParent];
        }
        GameScene *scene = [GameScene sceneWithSize:self.view.bounds.size];
        [self.view presentScene:scene];
        [self.gameOverMusic stop];
        [self.backgroundMusic stop];
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    
    // TAP TO START - Logic and Removal
    if (!self.ball.physicsBody.dynamic)
    {
        [self.tapToStart removeFromParent];
        self.ball.physicsBody.dynamic = YES;
        [self.ball.physicsBody applyImpulse:CGVectorMake([Utilites randomWithMin:1.0 max:20.0], [Utilites randomWithMin:50.0 max:80.0])];
        
        [self spawnBrickRows];
    }
    
    // Touch on Flippers logic
    if (touchLocation.x > 188)
    {
//        NSLog(@"Right Flipper Tapped");
        NSArray *sequence = @[[SKAction runBlock:^{self.rightFlipperActive = YES;}],
                              [SKAction rotateToAngle:-45 * M_PI / 180 duration:0.1],
                              [SKAction runBlock:^{self.rightFlipperActive = NO;}]];
        
        [self.rightFlipper runAction:[SKAction sequence:sequence]];
    }
    if (touchLocation.x < 188)
    {
//        NSLog(@"Left Flipper Tapped");
        NSArray *sequence = @[[SKAction runBlock:^{self.leftFlipperActive = YES;}],
                              [SKAction rotateToAngle:+45 * M_PI / 180 duration:0.1],
                              [SKAction runBlock:^{self.leftFlipperActive = NO;}]];
        
        [self.leftFlipper runAction:[SKAction sequence:sequence]];
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    if (touchLocation.x > 188)
    {
//        NSLog(@"Right Flipper Tapped");
        NSArray *sequence = @[[SKAction rotateToAngle:0 * M_PI / 180 duration:0.1]];
        
        [self.rightFlipper runAction:[SKAction sequence:sequence]];
    }
    if (touchLocation.x < 188)
    {
//        NSLog(@"Left Flipper Tapped");
        NSArray *sequence = @[[SKAction rotateToAngle:0 * M_PI / 180 duration:0.1]];
        
        [self.leftFlipper runAction:[SKAction sequence:sequence]];
    }
    
}

- (void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
    if(self.gameOver)
    {
        [self performGameOver];
        return;
    }
    if (self.lastUpdateTimeInterval)
    {
        self.timeSinceBrickAdded += currentTime - self.lastUpdateTimeInterval;
        self.totalGameTime += currentTime - self.lastUpdateTimeInterval;
    }
    if (self.timeSinceBrickAdded > self.addBrickTimeInterval && !self.gameOver)
    {
        [self spawnBrickRows];
        self.timeSinceBrickAdded = 0;
    }
    
    self.lastUpdateTimeInterval = currentTime;
    
    // Difficulty increase by game time
    if (self.totalGameTime > 480)
    {
        self.addBrickTimeInterval = 8;
    }
    else if (self.totalGameTime > 240)
    {
        self.addBrickTimeInterval = 14;
    }
    else if (self.totalGameTime > 120)
    {
        self.addBrickTimeInterval = 16;
    }
    else if (self.totalGameTime > 50)
    {
        self.addBrickTimeInterval = 18;
    }
}

#pragma mark - Setup Methods

- (void)setupSounds
{
    // Background sound
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"" withExtension:@"mp3"];
//    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
//    self.backgroundMusic.numberOfLoops = -1;
//    [self.backgroundMusic prepareToPlay];
//    [self.backgroundMusic play];
//    
//    // Gameover sound
//    NSURL *gameOverUrl = [[NSBundle mainBundle] URLForResource:@"" withExtension:@"mp3"];
//    self.gameOverMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:gameOverUrl error:nil];
//    self.gameOverMusic.numberOfLoops = -1;
//    [self.gameOverMusic prepareToPlay];
}

#pragma mark - Custom Methods

- (void)addBrickRowWithSize:(CGSize)size AndScreenSize:(CGSize)screenSize
{
//    int xPos;
//    int yPos;
    int rowOneHeight = 760;
    int rowTwoHeight = 780;
    int rowThreeHeight = 800;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        screenSize = [[UIScreen mainScreen] bounds].size;
        // iPhone 5/5s/5c RCL: Removed a brick...
        if (screenSize.height == 568)
        {
            for (int i = 0; i < 7; i++)
            {
                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA];
                
                int xPos = size.width/6.5 * (i+.5);
                // increment yPos by 20 for another row(size of brick)
                int yPos = rowThreeHeight-30;
                //        brickA.position = CGPointMake(xPos+44, yPos+220);
                brickA.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickA];
                [self addChild:brickA];
            }
            for (int i = 0; i < 7; i++)
            {
                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA];
                
                int xPos = size.width/6.5 * (i+.5); // int xPos = size.width/7.5 * (i+.5); i+.5
                int yPos = rowTwoHeight-30;
                brickA.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickA];
                [self addChild:brickA];
            }
            for (int i = 0; i < 7; i++)
            {
                BrickNode *brickB = [BrickNode brickRowOfType:BrickTypeB];
                
                int xPos = size.width/6.5 * (i+.5);
                int yPos = rowOneHeight-30;
                brickB.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickB];
                [self addChild:brickB];
            }
        }
        // iPhone 6 RCL: correct spacing
        else if (screenSize.height == 667)
        {
            SKColor *red = [SKColor redColor];
            SKColor *green = [SKColor greenColor];
            SKColor *darkGray = [SKColor darkGrayColor];
            SKColor *cyan = [SKColor cyanColor];
            SKColor *white = [SKColor whiteColor];
            SKColor *yellow = [SKColor yellowColor];
            SKColor *orange = [SKColor orangeColor];
            SKColor *purple = [SKColor purpleColor];
            SKColor *gray = [SKColor grayColor];
            SKColor *lightGray = [SKColor lightGrayColor];
            SKColor *black = [SKColor blackColor];
            SKColor *blue = [SKColor blueColor];
            SKColor *brown = [SKColor brownColor];
            SKColor *magenta = [SKColor magentaColor];
            
            for (int i = 0; i < 8; i++)
            {
                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA AndBrickColor:red];
                
                int xPos = size.width/7.5 * (i+.5);
                // increment yPos by 20 for another row(size of brick)
                int yPos = rowThreeHeight;
                //        brickA.position = CGPointMake(xPos+44, yPos+220);
                brickA.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickA];
                [self addChild:brickA];
            }
            for (int i = 0; i < 8; i++)
            {
                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA AndBrickColor:red];
                
                int xPos = size.width/7.5 * (i+.5); // int xPos = size.width/7.5 * (i+.5); i+.5
                int yPos = rowTwoHeight;
                brickA.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickA];
                [self addChild:brickA];
            }
            for (int i = 0; i < 8; i++)
            {
                BrickNode *brickB = [BrickNode brickRowOfType:BrickTypeB AndBrickColor:green];
                
                int xPos = size.width/7.5 * (i+.5);
                int yPos = rowOneHeight;
                brickB.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickB];
                [self addChild:brickB];
            }
//            for (int i = 0; i < 8; i++)
//            {
//                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA];
//                
//                int xPos = size.width/7.5 * (i+.5);
//                // increment yPos by 20 for another row(size of brick)
//                int yPos = rowThreeHeight;
//                //        brickA.position = CGPointMake(xPos+44, yPos+220);
//                brickA.position = CGPointMake(xPos-10, yPos);
//                
//                [BrickNode moveBricks:brickA];
//                [self addChild:brickA];
//            }
//            for (int i = 0; i < 8; i++)
//            {
//                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA];
//                
//                int xPos = size.width/7.5 * (i+.5); // int xPos = size.width/7.5 * (i+.5); i+.5
//                int yPos = rowTwoHeight;
//                brickA.position = CGPointMake(xPos-10, yPos);
//                
//                [BrickNode moveBricks:brickA];
//                [self addChild:brickA];
//            }
//            for (int i = 0; i < 8; i++)
//            {
//                BrickNode *brickB = [BrickNode brickRowOfType:BrickTypeB];
//                
//                int xPos = size.width/7.5 * (i+.5);
//                int yPos = rowOneHeight;
//                brickB.position = CGPointMake(xPos-10, yPos);
//                
//                [BrickNode moveBricks:brickB];
//                [self addChild:brickB];
//            }
        }
        // iPhone 6+ RCL: close nuff...added an extra brick
        else if (screenSize.height == 736)
        {
            for (int i = 0; i < 9; i++)
            {
                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA];
                
                int xPos = size.width/8.5 * (i+.5);
                // increment yPos by 20 for another row(size of brick)
                int yPos = rowThreeHeight;
                //        brickA.position = CGPointMake(xPos+44, yPos+220);
                brickA.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickA];
                [self addChild:brickA];
            }
            for (int i = 0; i < 9; i++)
            {
                BrickNode *brickA = [BrickNode brickRowOfType:BrickTypeA];
                
                int xPos = size.width/8.5 * (i+.5); // int xPos = size.width/7.5 * (i+.5); i+.5
                int yPos = rowTwoHeight;
                brickA.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickA];
                [self addChild:brickA];
            }
            for (int i = 0; i < 9; i++)
            {
                BrickNode *brickB = [BrickNode brickRowOfType:BrickTypeB];
                
                int xPos = size.width/8.5 * (i+.5);
                int yPos = rowOneHeight;
                brickB.position = CGPointMake(xPos-10, yPos);
                
                [BrickNode moveBricks:brickB];
                [self addChild:brickB];
            }
        }
    }
    
}

- (void)spawnBrickRows
{
    SKAction *spawn = [SKAction runBlock:^{
        // scene's size
        [self addBrickRowWithSize:self.size AndScreenSize:(self.screenSize)];
    }];
    [self runAction:spawn];
}

- (void)addPoints:(NSInteger)points
{
    HUDNode *hud = (HUDNode *)[world childNodeWithName:@"HUD"];
    [hud addPoints:points];
}

-(void)loseLife
{
    HUDNode *hud = (HUDNode *)[world childNodeWithName:@"HUD"];
    self.gameOver = [hud loseLife];
}

- (void)performGameOver
{
    if(!self.gameOverDisplayed)
    {
        GameOverNode *gameOver = [GameOverNode gameOverAtPosition:CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidX(self.view.bounds))];
        [self addChild:gameOver];
        
        self.gameOverDisplayed = YES;
        
        [self.backgroundMusic stop];
        [self.gameOverMusic play];
    }
}

- (void)explosionAtPosition:(CGPoint)position
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:@"BrickExplosion" ofType:@"sks"]; // particle effect
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    explosion.position = position;
    [self addChild:explosion];
    
    [explosion runAction:[SKAction waitForDuration:0.2] completion:^{
        [explosion removeFromParent];
    }];
}

@end
























