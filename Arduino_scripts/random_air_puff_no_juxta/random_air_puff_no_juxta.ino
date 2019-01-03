//Dr. Anton Sheinin, TAU 2017
/*the procedure for activation of two solenoid valves
 * the valve choice (1 or 2) and the delay between two activation cycles (15 - 19 sec) is determined by the random number.
 * During one valve activation cycle, the valve is activated 5 times.
 * The device is also sends a voltage signal for the indication of the valve activation:
 * for valve1, the device sends 5V from the devoted BNC
 * for valve2, the device sends 2.5V from the devoted BNC*/

//#include <avr/interrupt.h>
  
//initialize some global variables
long Valve_randNumber;  //random number from 1 to 2 for valve choice
long Delay_randNumber;  //random number from 15 to 19 for time delay in the loop
/////////////////////////////// These parameters determine the valve activation timing during the cycle /////////////////////////
long valveOn = 100;           //the valve open time in the activation sequence, in ms
long valveOff = 100;          //the valve close time in the activation sequence, in ms
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int cyclenum = 0;
void setup(){
  // initialize serial
  Serial.begin(9600);
  // initialize digital pin 11 as an output for Valve1 activation
  pinMode(11, OUTPUT);
  // initialize digital pin 12 as an output for Valve2 activation.
  pinMode(12, OUTPUT);
  // initialize digital pin 8 as an output for Valve1 indication (sends 5V on activation)
  pinMode(8, OUTPUT);
  // initialize digital pin 4 as an output for Valve2 indication (sends 2.5V on activation, through the resistor voltage divider)
  pinMode(4, OUTPUT);
  // attach interrupt for trigger on digital pin 2
  // initialize digital pin 10 as an output for the interrupts-tied LED (on board LED)
  pinMode(10, OUTPUT);
  digitalWrite(10, LOW);        // Make pin 10 low, switch LED off
  pinMode(2, INPUT);            // Pin 2 is input to which a "TRIGGER IN" BNC (TTL) is connected = INT0; an external 10k pulldown  resistor is used
  pinMode(3, INPUT);     // Pin 3 is input to which a constantly closed "STOP" switch is connected = INT1; an external 10k pulldown  resistor is used
  attachInterrupt(0, StartinterruptRoutine, RISING);
  attachInterrupt(1, STOPinterruptRoutine, RISING);
  //random numbers gen initialization:
  // if analog input pin 0 is unconnected, random analog
  // noise will cause the call to randomSeed() to generate
  // different seed numbers each time the sketch runs.
  // randomSeed() will then shuffle the random function.
  randomSeed(analogRead(0));  //random for valve choice
  Serial.println("Waiting for the trigger...");

}

void loop() {
if (digitalRead(10) == HIGH)  //start the loop ONLY if the pin 10 is HIGH
{ 
  Serial.print("Cycle No. ");
  Serial.println(cyclenum);
  Valve_randNumberGen();
  Delay_randNumberGen();
    switch (Valve_randNumber) {
      case 1:
        {
          ActivateValve1();
        }
      break;
      case 2:
        {
          ActivateValve1();
        }
      break;
      default: 
      break;
    }
  cyclenum++;
  delay((Delay_randNumber*1000)-valveOff);  //wait for the generated random delay minus the valve close time, in seconds
if (digitalRead(10) == LOW)  //end the loop if the pin 10 is LOW {
  stop_it();
}
}

void Valve_randNumberGen() {
// Valve choice - random number from 1 to 2
  Valve_randNumber = random(1,3);
  Serial.print("Random number for valve choice =");
  Serial.println(Valve_randNumber);
}

void Delay_randNumberGen() {
// Loop delay time - random number from 15 to 19
  Delay_randNumber = random(13,17);
  Serial.print("Random number for time delay (sec) =");
  Serial.println(Delay_randNumber); 
}

void ActivateValve1() {
  int i = 1;
  Serial.println("Valve1 will be activated 5 times; 5V is sent to Valve1 BNC");
  Serial.print("Valve ON time (ms)= ");
  Serial.println(valveOn);
  Serial.print("Valve OFF time (ms)= ");
  Serial.println(valveOn);
  while(i < 6){
  Serial.print("trial=");
  Serial.println(i);
  digitalWrite(11, HIGH);
  digitalWrite(8, HIGH);
  delay(valveOn);
  digitalWrite(11, LOW);
  digitalWrite(8, LOW);
  delay(valveOff);
  i++;
}
  Serial.println("*******");
}

void ActivateValve2() {
  int i = 1;
  Serial.println("Valve2 will be activated 5 times; 2.5V is sent to Valve2 BNC");
  Serial.print("Valve ON time (ms)= ");
  Serial.println(valveOn);
  Serial.print("Valve OFF time (ms)= ");
  Serial.println(valveOn);
  while(i < 6){
  Serial.print("trial=");
  Serial.println(i);
  digitalWrite(12, HIGH);
  digitalWrite(4, HIGH);
  delay(valveOn);
  digitalWrite(12, LOW);
  digitalWrite(4, LOW);
  delay(valveOff);
  i++;
}
  Serial.println("*******");
}


void StartinterruptRoutine(){              // Interrupt service routine; pin 10 turns HIGH on interrput from pin 2
  digitalWrite(10, HIGH);
}

void STOPinterruptRoutine(){              // Interrupt service routine; pin 10 turns LOW on interrput from pin 3
  digitalWrite(10, LOW);
}

void stop_it()
{
 Serial.println("STOP button pressed - the program is aborted; the valves closed");
 Serial.println("Press RESET button to initiate the program");
 while(1);  //stop the loop() execution
 //and force the digital outputs for valves and the indication to LOW
  digitalWrite(11, LOW);
  digitalWrite(8, LOW);
  digitalWrite(12, LOW);
  digitalWrite(4, LOW);
}


