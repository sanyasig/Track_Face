import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import processing.serial.*;       

Capture video;
OpenCV opencv;
int midScreenRectX;
int midScreenRectY;
int rectSize;
int imageSizeX = 320;
int imageSizeY = 240;
int midScreenY = imageSizeY/2;
int midScreenX = imageSizeX/2;
int midScreenWindow = 10;
int stepSize =1;
int midFaceX = 0;
int midFaceY = 0;
int currentMidFaceX = 0;
int currentMidFaceY = 0;
int servoTiltPosition = 60;
int servoPanPosition = 90;
char tiltChannel = 1;
char panChannel = 0;
char redChannel = 2;
char greenChannel = 2;
int frameBy = 1;
int errorRate = 20;

Serial port;
void setup() {
  size(imageSizeX, imageSizeY);
  rectSize = 30;
  video = new Capture(this, imageSizeX/frameBy, imageSizeY/frameBy, "/dev/video1");
  opencv = new OpenCV(this,imageSizeX/frameBy, imageSizeY/frameBy);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
   
  video.start();
  port = new Serial(this, Serial.list()[0], 57600);   //Baud rate is set to 57600 to match the Arduino baud rate.

  // print usage
  println( "Drag mouse on X-axis inside this sketch window to change contrast" );
  println( "Drag mouse on Y-axis inside this sketch window to change brightness" );
  
  //Send the initial pan/tilt angles to the Arduino to set the device up to look straight forward.
  port.write(tiltChannel);    //Send the Tilt Servo ID
  port.write(servoTiltPosition);  //Send the Tilt Position (currently 90 degrees)
  port.write(panChannel);         //Send the Pan Servo ID
  port.write(servoPanPosition);  
}

void draw() {
 //scale(2);
  opencv.loadImage(video);

  image(video, 0, 0 );

  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  Rectangle[] faces = opencv.detect();
  // draw face area(s)
  noFill();
  stroke(255,0,0);
  for( int i=0; i<faces.length; i++ ) {
    rect( faces[i].x, faces[i].y, faces[i].width, faces[i].height );
  }
  
  //Find out if any faces were detected.
  if(faces.length > 0){
    port.write(greenChannel);
    println("sending green chanell");
    //If a face was found, find the midpoint of the first face in the frame.
    //NOTE: The .x and .y of the face rectangle corresponds to the upper left corner of the rectangle,
    //      so we manipulate these values to find the midpoint of the rectangle.
    currentMidFaceX = faces[0].x + (faces[0].width/2);
    currentMidFaceY = faces[0].y + (faces[0].height/2);
    if(midFaceX == 0 && midFaceY == 0){
       midFaceX = faces[0].x + (faces[0].width/2);
       midFaceY = faces[0].y + (faces[0].height/2);
    }
    
    if ((currentMidFaceX < midFaceX - errorRate) || (currentMidFaceX > midFaceX + errorRate)){
    midFaceX = faces[0].x + (faces[0].width/2);
    }
    if ((currentMidFaceY < midFaceY - errorRate) || (currentMidFaceY > midFaceY + errorRate)){
    midFaceY = faces[0].y + (faces[0].height/2);
    }
    
   println("mid face is " + midFaceX + " "+ midFaceY);
   println("and mouse pointer is " + mouseX +" " + mouseY);
    
    //Find out if the Y component of the face is below the middle of the screen.
    if(midFaceY < (midScreenY)){
      if(servoTiltPosition >= 5)servoTiltPosition -= stepSize; //If it is below the middle of the screen, update the tilt position variable to lower the tilt servo.
    }
    //Find out if the Y component of the face is above the middle of the screen.
    else if(midFaceY > (midScreenY)){
      if(servoTiltPosition <= 175)servoTiltPosition +=stepSize; //Update the tilt position variable to raise the tilt servo.
    }
    //Find out if the X component of the face is to the left of the middle of the screen.
    if(midFaceX > (midScreenX - 20)){
      if(servoPanPosition >= 5)servoPanPosition -= stepSize; //Update the pan position variable to move the servo to the left.
    }
    //Find out if the X component of the face is to the right of the middle of the screen.
    else if(midFaceX < (midScreenX + 20)){
      if(servoPanPosition <= 175)servoPanPosition +=stepSize; //Update the pan position variable to move the servo to the right.
    }
    
  }else{
   println("sending red chanell");
   port.write(redChannel); 
    
  }
  println("servo tilt position is " + servoTiltPosition);
  println("servo pan position is " + servoPanPosition);
  port.write(tiltChannel);    //Send the Tilt Servo ID
  port.write(servoTiltPosition);  //Send the Tilt Position (currently 90 degrees)
  port.write(panChannel);         //Send the Pan Servo ID
  port.write(servoPanPosition);  
     noFill();
  stroke(0, 0, 0);
  rect(midScreenX, midScreenY, rectSize, rectSize, 8);
  //delay(1);
}

void captureEvent(Capture c) {
  c.read();
}

