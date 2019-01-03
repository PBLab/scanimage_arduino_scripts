//this procedure will activate the TTL for triggering the laser in a specified sequence
//the procedure waits for the trigger - either the press on "START" pushbutton or a high TTL signal
//on "TTL START" BNC.

//27.7.2017 - the control of PMT gain is added
//the PMT gain will be reduced nn ms before the laser activation
//conections with the PMT power supply: 
// "SDL" to "SDL (A5)"
// "SCL" to "SCL (A4)"
//The left channel of the power supply) is used

#include <Wire.h>
#include <Adafruit_MCP4725.h>

Adafruit_MCP4725 dac;

int laser = 4;       //for laser trigger
int startcycle = 3;  //start button
int TTLstart = 2;    //start TTL
int start_state;
int TTL_state;
int cycle_num = 4;
//****************THESE PARAMETERS SET THE PMT GAIN******************************
int PMT_low_gain = 1600; //the LOW gain of PMT (use number between 0 and 4095)
int PMT_high_gain = 3400; //the HIGH gain of PMT (use number between 0 and 4095)
//*******************************************************************************

void setup() {
  pinMode(startcycle,INPUT_PULLUP);
  pinMode(TTLstart,INPUT);
  pinMode(laser,OUTPUT);
  // initialize serial:
  Serial.begin(9600);
  //initialize dac
  dac.begin(0x62);  //DAC1 (left side of PS box); for DAC2 (right side of PS box) use command (0x63)
  dac.setVoltage(PMT_high_gain, false);  //set PMT to low gain
}

void loop() {
  start_state = digitalRead(startcycle); 
  TTL_state = digitalRead(TTLstart); 
//  Serial.println(TTL_state);
    if ((start_state == LOW)||(TTL_state == HIGH)) { 
      finite_loop();
    }
}



void finite_loop(){
  Serial.println("Start cycling...");
  for(int i=0; i<cycle_num; i++) {  
  toggle_laser();
  delay(40000-233);
  dac.setVoltage(PMT_low_gain, false);  //set PMT to low gain
  Serial.print("end of cycle ");
  Serial.println(i);
  }
  Serial.println("END");
}


void toggle_laser() {
  for(int j=0; j<120; j++) {  //120 times, i.e. pulses for 40 sec: 40,000 ms/(100 ms + 233 ms) = 120.12
//  for(int j=0; j<5; j++) {  //for tests
  dac.setVoltage(PMT_low_gain, false);  //set PMT to low gain
  delay(100);
  digitalWrite(laser,HIGH);
  delay(100); //ON time
  digitalWrite(laser,LOW);
  delay(10);
  dac.setVoltage(PMT_high_gain, false); //set PMT to high gain
  delay(123); //OFF time; 233 ms together with two PMT delays (2 x 10 ms)
  }
}


