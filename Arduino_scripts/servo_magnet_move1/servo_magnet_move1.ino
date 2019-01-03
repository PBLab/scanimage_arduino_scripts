//control of small servo motor by the button switch
//the motor turns to the specified degree and returns to initial position
//Dr. Anton Sheinin, TAU, 2017. 

#include <Servo.h>
Servo myservo;                    // create servo object to control a servo
int servoPin = 7;                 // the pin for servo control
int buttonPin = 2;                // the pin for the button
int outputPin = 5;                // the pin for the output BNC (sends HIGH or LOW)
int angle = 0;                    // variable to write an angle to the servo
int state;                        // state to monitor the button
//////////////////////////////CHANGEABLE VALUES///////////////////////////////////////////////////////
int waittime = 15000;             // wait time (in msec) for the servo to spend in desired position
int newangle = 90;                // the new value of angle 
/////////////////////////////////////////////////////////////////////////////////////////////////////

void setup() {
  myservo.attach(servoPin);        // attaches the servo to its pin
  myservo.write(0);                //inital position; 0 degree
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(outputPin, OUTPUT);
}
  
void loop() {
  state = digitalRead(buttonPin); 
//  Serial.println(state); 
  if (state == LOW)  {
    angle = newangle;              
    digitalWrite(outputPin, HIGH); //the output pin and BNC are HIGH
    myservo.write(angle);
    delay(waittime);              // wait the specified time    
    digitalWrite(outputPin, LOW); // the output pin and BNC are LOW
    myservo.write(0);             // return servo to initial position
    delay(15);                    // short delay to send the command to servo
  }
}


