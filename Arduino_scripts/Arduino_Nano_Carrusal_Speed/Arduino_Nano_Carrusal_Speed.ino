//=================================================================

         //Mouse Training System Experiment - R.P.M SPEED:
      //The system measures the speed of a mouse on a carrousel
         //and sent it to a microscope via Analog Channel with
       //ARDUINO NANO and MCP4725 using Interapts and Reed Switch.
        //The result also presented on LCD display - LCD1602.

           //Version 1.0 June,2016
          //Copyright 2016 Tomer Yehudar.
             //For More Projects: 
            //tomeryehu@gmail.com
           //tomeryehudar.wix.com/arduino

//=================================================================


//Liberis Of The Program:
//-----------------------

#include <Wire.h>
#include <Adafruit_MCP4725.h>
#include <LiquidCrystal_I2C.h>

//Varibles Of The Program:
//-----------------------

LiquidCrystal_I2C lcd(0x27, 16, 2);
Adafruit_MCP4725 Analog_Channel;

int Carrousel_Speed = 0;//Speed r.p.m;
int Velocity = 0; //Speed cm/s.
int Num_Of_Magnets = 4;
float Calibration = 5.2 ; //5.2; //After Calibration need to divaded in 5.2

volatile int Reed_Pulses = 0;

float Voltage_Speed = 0;
float Sensitivity = 200.0; //The max speed of the mouse.

//For Sending Speed To Arduino:
int PWM_Send_Speed = 0;

void setup(void) {

  //For Sending Speed To Arduino:
    //pinMode(3,OUTPUT);

  // Initialize the lcd:
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  
   LoadingLCDScreen();

  
  lcd.setCursor(0, 0);
  lcd.print("Mouse ");
    lcd.setCursor(0, 1);
  lcd.print("Speed: ");

  Analog_Channel_Setup();

  INTERRUPT_SETUP ();

   //Serial Communication:
  Serial.begin(9600);

}

void loop(void) {

  CarrouselSpeed();
  Serial.println(Carrousel_Speed);
  //Change The Speed From RPM To Volt:
  Voltage_Speed = (float)Carrousel_Speed * 5.0 / Sensitivity;
  if (Voltage_Speed > 5.0)
    Voltage_Speed = 5.0; //Limit Of Analog Channel.
    //Serial.println(Voltage_Speed);

  //For Sending Speed To Microscope:
    Analog_Channel.setVoltage(Voltage_Speed, false);

  //Print the Speed (r.p.m):
    lcd.setCursor(6, 0);
  lcd.print("          ");
  lcd.setCursor(7, 0);
  lcd.print(Carrousel_Speed);
    //lcd.setCursor(4, 0);
  lcd.print(" r.p.m");
    //Print the Speed (m/s): //Carrousel perimeter is 37.7 cm so Velocity is perimeter*rpm/60;
    Velocity = Carrousel_Speed*37.7/60.0;
    lcd.setCursor(6, 1);
  lcd.print("          ");
  lcd.setCursor(7, 1);
  lcd.print(Velocity);
    //lcd.setCursor(4, 0);
  lcd.print(" cm/s");
  if(Carrousel_Speed>400 || Carrousel_Speed<0){
    lcd.setCursor(6, 0);
    lcd.print(" *Error*  ");
        lcd.setCursor(6, 1);
    lcd.print(" *Error*  ");
  }
  
  //analogWrite(3,PWM_Send_Speed);
  //Serial.println(PWM_Send_Speed);

// if(Serial.available()>0){
//  int c = Serial.parseInt();
//  Serial.println(c);
//  Analog_Channel.setVoltage(c, false);
// }

}


void Analog_Channel_Setup() {
  // Set A2 and A3 as Outputs to make them our GND and Vcc,
  //which will power the MCP4725
//  pinMode(A2, OUTPUT);
//  pinMode(A3, OUTPUT);
//  digitalWrite(A2, LOW);//Set A2 as GND
//  digitalWrite(A3, HIGH);//Set A3 as Vcc
    // For Adafruit MCP4725A1 the address is 0x62 (default) or 0x63 (ADDR pin tied to VCC)
  // For MCP4725A0 the address is 0x60 or 0x61
  // For MCP4725A2 the address is 0x64 or 0x65
  Analog_Channel.begin(0x62);
}

void INTERRUPT_SETUP() {

  pinMode(2, INPUT); //initializes digital pin 2 as an input (AND USE PULL DOWN RESISTOR ON THE CIRCUT PCB).
  attachInterrupt(digitalPinToInterrupt(2), Reed_Pulses_INTERRUPTS, RISING); //and the interrupt is attached
}

void Reed_Pulses_INTERRUPTS()     //This is the function that the interupt calls 
{
  Reed_Pulses++;  //This function measures the rising and falling edge of the hall effect sensors signal
}


//For 0.5 Second:
void CarrouselSpeed() {//Calculate Flow.

  Reed_Pulses = 0;      //Set "Reed_Pulses" to 0 ready for calculations.
  sei();               //Enables interrupts.
  delay(1000);        //Wait 1 second. or 0.5 sec 
  detachInterrupt(2); //Disable interrupts On Spesific pin.
  Carrousel_Speed = Reed_Pulses * 60 / Num_Of_Magnets; //Num Of Pulses x frequency of one minute = RPM.
  Carrousel_Speed=Carrousel_Speed/Calibration; //After Calibration need to divaded in 5.2;
}

void LoadingLCDScreen(){

   lcd.print("|  Arduino    |");
    lcd.setCursor(0, 1);
  lcd.print("|  Developer  |");
  delay(1200);
    lcd.clear();
    lcd.setCursor(0, 0);
  lcd.print("|Tomer Yehudar|");
  delay(1200);
  lcd.clear();
    lcd.setCursor(0, 0);
  lcd.print(" tomeryehu@");
      lcd.setCursor(6, 1);
  lcd.print("gmail.com");
  delay(1200);
  lcd.clear();
}

//For 1 Second:
/*
void CarrouselSpeed() {//Calculate Flow.

 Reed_Pulses = 0;      //Set NbTops to 0 ready for calculations
 sei();            //Enables interrupts
 delay (1000);      //Wait 1 second
 cli();
 Carrousel_Speed= Reed_Pulses * 60/Num_Of_Magnets; //(Pulse frequency x 60) / 7.5Q, = flow rate in L/hour
} */


