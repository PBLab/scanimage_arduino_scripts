 int laser= 2;
 int led= 38;
 int TDT= 13;
 int stim,Cycle_length,stim_length,stim_delay, NumCyl, cycles, ITI;
 
 // Ctrl+Shift+M to start
void setup() 
{
  // define led pins 
  pinMode(led,OUTPUT);
  pinMode(laser,OUTPUT);
  pinMode(TDT,OUTPUT);
  
  // initialize serial:
  Serial.begin(9600);
  Serial.println("serial established");
  readInputs();
}

void readInputs(){
  
       Serial.println("Number of Stimulation =");
      stim = 3;//waitForNumber();
      
      // Serial.println("Cycle length=");
      //Cycle_length =  waitForNumber();      
      
      Serial.println("Stimulation length [ms] =");
      stim_length = 150;//waitForNumber();
      
      Serial.println("Delay between length [ms]=");
      stim_delay = 275;//waitForNumber();

      Serial.println("number of cycles");
      cycles = 100; //waitForNumber();

      Serial.println("inter trial interval in msec");
      ITI = 5000;//waitForNumber();
      //printValues();
      NumCyl=0;
}

void loop() {
      while (1) { // Endles loop
                      
                startProgram();    // Start using the laser
                NumCyl=NumCyl+1;
                // next run check
                //Serial.println("Finished! \nAgain Same sequence ? (1=Yes, 0=No)");
                //int answer = waitForNumber();
                if (NumCyl==cycles)
                  readInputs();
                delay(ITI);  
                //if (answer ==  0)
                  //readInputs();                   
                  }
              }

void startProgram(){
    Serial.println("Using the Laser!!\n");
    for(int i=0; i<stim; i++) {
            digitalWrite(laser,HIGH);
            digitalWrite(led,HIGH);
            digitalWrite(TDT,HIGH);
            delay(stim_length);
            
            digitalWrite(laser,LOW);
            digitalWrite(led,LOW);
            digitalWrite(TDT,LOW);
            delay(stim_delay);   
            
    }
}





// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Secondary Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
int waitForNumber(){
      while (Serial.available() == 0) ;
      int value = Serial.parseInt();
//      int value = Serial.read()-48;;
      Serial.println(value);
      return value;
}

void printValues(){
 Serial.println("The Values Are:");
myPrint(stim); myPrint(Cycle_length); myPrint(stim_length); Serial.println(stim_delay); Serial.println();
}
void myPrint(int i){Serial.print(i);  Serial.print(", ");}
