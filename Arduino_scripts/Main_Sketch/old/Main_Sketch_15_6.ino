//=================================================================

               //Mouse Training System Experiment:
                   //Version 1.97 June,2016
                  //Copyright 2016 Tomer Yehudar.
                       //For More Projects: 
                      //tomeryehu@gmail.com
                   //tomeryehudar.wix.com/arduino
//=================================================================

//Liberis Of The Program:
//-----------------------
  #include <Servo.h>
  #include <Wire.h> //For Analog Channel Communication.
  #include <Adafruit_MCP4725.h> //For Analog Channel Communication.


//Variables Of The Program:
//-------------------------

  #define ON 1
  #define OFF 0

  // Clock Timer:
  //=============
  /*General Timer:*/ unsigned long Current_Time = 0;
  /*Tone Timer:*/unsigned long Current_Time_Tone = 0;
  /*Water Timer:*/unsigned long Current_Time_Water = 0;
  /*Vaccum Timer:*/unsigned long Current_Time_Vaccum = 0;
  /*Servo Timer*/ unsigned long Current_Time_Servo = 0;

  //Sensors & Component:
  //====================
  /*Analog Channel:*/ Adafruit_MCP4725 Analog_Channel;
  /*Servo Motor:*/   Servo Servo1; int Texture0_Angle = 0, Texture1_Angle = 180;
  /*Servo Motor:*/   int  Rand_Angle[11], Rand_Circle = 5, Current_Circle = 1, Rand_Texture = 0;
  /*Servo Motor:*/   int Move_Servo_Duration = 300; boolean Texture_Flag = 1;
  /*Stepper Motor*/  byte End_Angle = 93; float Stepper_Speed = 0.01; /*Speed: 0.01->1*/ boolean Stepper_Movement_Flag = 0;
  /*Stepper Motor*/   int Actual_Step = 0, End_Steps = End_Angle * 200 / 360; //200 Steps are 360 Degrees (Module:A4988).
  /*Carrousel Speed*/ //int Carrousel_Speed = 0; --> Go To "Arduino - Send Data".
  /*Carrousel Speed*/ int Reed_Pulses = 0, Num_Of_Magnets = 21;
  /* Lick Circuit : */ boolean Last_Lick_State = -1; //Debounce for lick - Send Lick only 1 Time When Lick Occurred.
  /* Punishment: */ int Punishment_Counter = 0;
  /*Water Process:*/ int WaterFlag = 0;
  boolean Valve_R_Flag = 0, Valve_L_Flag = 0; //To Open And Close Valve From Matlab

  //GUI - MATLAB Varibles:  

    char Command = 0;
    int BaudRate = 19200; // Serial Communication.

    //GUI - Matlab Send Data:
    int Sample_Duration = 2 * 1000;
    int Retention_Duration = 2 * 1000;
    int Punishment_Duration = 5 * 1000;
    int Number_Of_Trials = 100, Actual_Trials = 0;
    int Tone_Duration = 0.1 * 1000;
    int Response_Time = 2 * 1000;
    int Vacuum_Duration = 0.1 * 1000;
    int Inter_Trial_Interval = 3 * 1000;
    //*New:
    int Water_Duration = 0.3 * 1000;
    int Number_Of_Repeats = 3, Actual_Repeats = 0;
    int Punishment_In_Punishment = 0;
	//int End_Angle = 90;  //Declared Up.
	int freq = 3.4 * 1000; //Hz.

    //Arduino - Send Data:
    unsigned long messageId = 1;
    unsigned long Training_Time = 0, Start_Training_Time = 0;
    int Trial_Beginning_Event = 0;
    int Lick_In_Response_Time = 0;
    int Lick_At_Correct_Port = -1;
    int Fisrt_Lick_In_Response_Time = 0; int Lick_Flag = 0; // For Send First Lick Only;
    String Stage_Of_Trail;
    int Carrousel_Speed = 0; //R.P.M


//Connections Pins Of The Program:
//--------------------------------
  /* Sound : */           byte Speaker=13;
  /* Lick Circuit : */    byte Lick1=50, Lick2=52;
  /* Solenoid Valves : */ byte Water_Valve1=42, Water_Valve2=44, Vacuum_Valve1=46, Vacuum_Valve2=48;
  /* Stepper Motor : */   byte DIR=9,STEP=8, StepperOff=35; //FIX 35 PIN (ENABLE PIN).
  /* Switch Stepper : */  byte Home_Switch = 38, End_Switch = 40;
  /* Servo Motor : */     byte Servo_Pin=39;
  /* Buttons Switch : */  byte B_Home=10, B_Run=12; // Not in use yet. 
  /* Carrousel Speed: */  byte Carrousel_Speed_Pin =A8; 
  /* Random Seed : */     byte Random_Pin=A0;
  /*Anlong Channel*/      byte Analog_GND = 18, Analog_VCC = 19; //I2C On Pins 20 ,21 On Mega Board.

//===================================================================================

//Setup:
void setup() {

  randomSeed(analogRead(Random_Pin)); //Create An Random Seed.
  Serial.begin(BaudRate);
  Connection_Setup();

}

//Main Loop:
void loop() {
  
  GUI_Send(); 


}


//Functions Of The Program:
//=========================


//Defined Connections:
//--------------------
void Connection_Setup(){

  //Sound:
   pinMode(Speaker,OUTPUT); 

  //Lick Circuit:
  pinMode(Lick1,INPUT_PULLUP); 
  pinMode(Lick2,INPUT_PULLUP);

  //Solenoid Valves:
  pinMode(Water_Valve1,OUTPUT);
  pinMode(Water_Valve2,OUTPUT);
  pinMode(Vacuum_Valve1,OUTPUT);
  pinMode(Vacuum_Valve2,OUTPUT);

  //Stepper Motor & Home Switch :
  pinMode(DIR,OUTPUT); 
  pinMode(STEP,OUTPUT); 
  pinMode(Home_Switch,INPUT_PULLUP);
  pinMode(End_Switch, INPUT_PULLUP);

  //Servo Motor:
   Servo1.attach(Servo_Pin); 

   //Analog Channel Setup:
   Analog_Channel_Setup();

}

void Analog_Channel_Setup() {
  // Set A2 and A3 as Outputs to make them our GND and Vcc,
  //which will power the MCP4725
  pinMode(Analog_GND, OUTPUT);
  pinMode(Analog_VCC, OUTPUT);
  digitalWrite(Analog_GND, LOW);//Set A2 as GND
  digitalWrite(Analog_VCC, HIGH);//Set A3 as Vcc
  // For Adafruit MCP4725A1 the address is 0x62 (default) or 0x63 (ADDR pin tied to VCC)
    // For MCP4725A0 the address is 0x60 or 0x61
  // For MCP4725A2 the address is 0x64 or 0x65
  Analog_Channel.begin(0x60);
}

//GUI - From Matlab:
//--------------------

//Send Commands From GUI to ARDUINO:

void GUI_Send(){
  
  //ARDUINO Recieve Commands:
  if (Serial.available()) {

	Punishment_Counter = 0; //Zero Counter Every New Training.
    Command = Serial.read();
    GUI_Settings();  //ARDUINO Recieve Settings.

    switch (Command) {

      //  For training stage 0: Licking from the lick ports.

      //Start Command:
    case 'Z': {
      Training_Stage_0();
      break;
    }

    //  For training stage 1: �Licking from the lick ports for water�:

            //Start Command:
      case 'A': {
        Training_Stage_1();
        break;
      }

    // For training stage 2 : �Licking only after an auditory cue�.

      //Start Command:
      case 'B': {
        Training_Stage_2();
        break;
      }

      //For training stage 3 : �Water delivered only after the first lick that follows the tone�.

      //Start Command:
      case 'C': {
        Training_Stage_3();
        break;
      }

     //For training stage 4: the full training (discrimination).

        //Start Command:
        case 'D': {
          Servo1.attach(Servo_Pin);
          Training_Stage_4();
          break;
        }

        //Stop Command:  *** REFILL **
        case 'S': {
          noTone(Speaker);
          Close_Solenoid(Water_Valve1);
          Close_Solenoid(Water_Valve2);
          break;
        }
    }
  }


}

void GUI_STOP() {

  //ARDUINO Recieve Commands:
  if (Serial.available()) {

    Command = Serial.read();

    if (Command == 'S') {
   // Serial.println();
    //  Serial.println("========   |  User Click Stop Training End !  |   ==========");
   // Serial.println();
      noTone(Speaker);
      Close_Solenoid(Water_Valve1);
      Close_Solenoid(Water_Valve2);
      Servo1.detach();
      while (digitalRead(Home_Switch))
        Stepper_Reset();
    }

    GUI_OPEN_VALVE();
  }
}

void GUI_OPEN_VALVE() {

  //ARDUINO Recieve Commands:
//  if (Serial.available()) {  --> Because I Put It In GUI Stop So Serial Buffer Wont Loses Date.

  //  Command = Serial.read();
    if (Command == 'R') {
      Stage_Of_Trail = "Ur";
      GUI_Recieve(); // Send Message To GUI.
      Valve_R_Flag = !Valve_R_Flag;
      if (Valve_R_Flag)
        Open_Solenoid(Water_Valve2);
      else
        Close_Solenoid(Water_Valve2);
    }
    if (Command == 'L') {
      Stage_Of_Trail = "Ur";
      GUI_Recieve(); // Send Message To GUI.
      Valve_L_Flag = !Valve_L_Flag;
      if (Valve_L_Flag)
        Open_Solenoid(Water_Valve1);
      else
        Close_Solenoid(Water_Valve1);
    }
  }



//Recieve Commands From ARDUINO to GUI & Microscope:

void GUI_Recieve() {

  //Send Data To Microscope:
  Send_To_Analog_Channel();


  //start each message with it's id so we can check no messages get lost.
  Serial.print(messageId);
  Serial.print("\t");

  //prints time since program started - this should be changed to elapsed time since beginning of trail
  Training_Time = millis() - Start_Training_Time;
  Serial.print(Training_Time);
  Serial.print("\t");

  //prints flag for type of message 1 if beginning of trial or 0 for lick event.
  Serial.print(Trial_Beginning_Event);
  Serial.print("\t");

  //prints texture id for current trial 1 or 2.
  Serial.print(Rand_Texture);
  Serial.print("\t");

  //prints lickEventCorrectTiming
  Serial.print(Lick_In_Response_Time);
  Serial.print("\t");

  //prints lickEventCorrectPort
  Serial.print(Lick_At_Correct_Port);
  Serial.print("\t");

  //prints lickEventIsFirstInResponseTime
  Serial.print(Fisrt_Lick_In_Response_Time);
  Serial.print("\t");

  //Prints stage along trial:
  Serial.print(Stage_Of_Trail);
  Serial.print("\t");

  //Prints Carrousel Speed:
  CarrouselSpeed();
  Serial.print(Carrousel_Speed);
  Serial.print("\t");

  //terminate message with carriage return
  Serial.print("\n");
  messageId++;
  Trial_Beginning_Event = 0;
  Lick_In_Response_Time = 0; //No Lick;
  Serial.flush(); //Clean Buffer For New Data.

} 

//Send Data To Microscope: 
void Send_To_Analog_Channel() {

  if (Trial_Beginning_Event)
    Analog_Channel.setVoltage(0.5, false); //Start Trail.
  else
    if (Lick_At_Correct_Port == -1 && Rand_Texture == 1) //Non Lick & Texture 1.
      Analog_Channel.setVoltage(1.0, false);
    else
      if (Lick_At_Correct_Port == -1 && Rand_Texture == 2) //Non Lick & Texture 2.
        Analog_Channel.setVoltage(1.5, false);
      else
        if (Lick_At_Correct_Port && Rand_Texture == 1)  //Correct Lick & Texture 1.
          Analog_Channel.setVoltage(3.5, false);
        else
          if (!Lick_At_Correct_Port && Rand_Texture == 1)  //Incorrect Lick & Texture 1.
            Analog_Channel.setVoltage(4, false);
          else
            if (Lick_At_Correct_Port && Rand_Texture == 2)//Correct Lick & Texture 2.
              Analog_Channel.setVoltage(4.5, false);
            else
              if (!Lick_At_Correct_Port && Rand_Texture == 2)//Incorrect Lick & Texture 2.
                Analog_Channel.setVoltage(5.0, false);
}

//Recieve Settings From GUI:
void GUI_Settings() {

  Number_Of_Trials = Serial.parseInt(); 
  Sample_Duration = Serial.parseInt();
  Retention_Duration = Serial.parseInt();
  Response_Time = Serial.parseInt();
  Inter_Trial_Interval = Serial.parseInt();
  Vacuum_Duration = Serial.parseInt(); 
  Tone_Duration = Serial.parseInt();
  Punishment_Duration = Serial.parseInt();
  Water_Duration = Serial.parseInt();
  Number_Of_Repeats = Serial.parseInt();
  Punishment_In_Punishment = Serial.parseInt();
  End_Angle = Serial.parseInt();
  freq = Serial.parseInt();
  End_Steps = End_Angle * 200 / 360; //200 Steps are 360 Degrees (Module:A4988).
}


//Reset & Calibration:
void Reset(){
  
  randomSeed(analogRead(Random_Pin)); //Create An Random Seed.
  Stepper_Reset();
  //Reset Variables:

}

void Stop() {


}

void Punishment() {

  Stage_Of_Trail = "Pu";
  Lick_At_Correct_Port = 0;
  if (Punishment_Counter <= Punishment_In_Punishment-1) {

	  Punishment_Counter++; // Punishment In Punishment Untill X Times.
	  GUI_Recieve();//Send Message To GUI.
	  //This :
	  unsigned long Current_Time_Punishment = millis();  //Current Time For Time Stamp Timer.
	  while (millis() - Current_Time_Punishment <= Punishment_Duration) {

		  GUI_STOP(); //Stop Tranning.
		  //If Lick Match Open Valve: 
		  switch (Lick_Match()) {
		  case 0: {
			  Lick_At_Correct_Port = 2;//If not match .
			  GUI_Recieve(); //Send Message After Lick;
			  Current_Time += Punishment_Duration; // Punishment In Punishment.
			  Punishment();
			  break;
		  }
		  case 1: {
			  Lick_At_Correct_Port = 1;
			  GUI_Recieve(); //Send Message After Lick.
			  Current_Time += Punishment_Duration; // Punishment In Punishment.
			  Punishment();
			  break;
		  }
		  case 2: {
			  Lick_At_Correct_Port = 1;
			  GUI_Recieve(); //Send Message After Lick.
			  Current_Time += Punishment_Duration; // Punishment In Punishment.
			  Punishment();
			  break;
		  }
		  case -1: {
			  Lick_At_Correct_Port = 0;//Non Lick.
			  break;
		  }
		  }
	  }
  }
   
}

//Count Timer - Doing Something In set time:
void Count_Timer() {



}

//  For training stage 0: Licking from the lick ports for water:

void Training_Stage_0() {

  Start_Training_Time = millis(); //For Calculate Training_Time.
  Trial_Beginning_Event = 0;
  Rand_Texture = 0;
  Lick_At_Correct_Port = 0;
  Fisrt_Lick_In_Response_Time = 0;
  Lick_Flag = 1; //Lift Flag Up;
  Lick_In_Response_Time = 0;
  Stage_Of_Trail = "Rr";
  GUI_Recieve(); // Send Message To GUI.
  Current_Time = millis();  //Current Time For Time Stamp Timer.
  while (1) {
    GUI_STOP(); //Stop Tranning.
    if (Command == 'S')
      goto STOP;

    if (millis() - Current_Time >= 5000) {//Send Message Every 1 Sec.
	  Lick_In_Response_Time = 0;
      Current_Time = millis();
      GUI_Recieve(); // Send Message To GUI.
    }

    if (Lick_Check_For_Other_Trannings() == 1) {
      WaterFlag = 1;
      Current_Time_Water = millis();
	  Current_Time = millis();
    }
    else
      if (Lick_Check_For_Other_Trannings() == 2) {
        WaterFlag = 2;
        Current_Time_Water = millis();
		Current_Time = millis();
      }
    if (WaterFlag == 1)
      Water_Process(1);
	if (WaterFlag == 2)
      Water_Process(2);
  }

  //END Of Trials:
  Trial_Beginning_Event = 2;
  GUI_Recieve();
    STOP:;


}

//  For training stage 1: Association between the cue and the water.

void Training_Stage_1() {

  Turn_Stepper(OFF);//thought to reduce noise
  Start_Training_Time = millis(); //For Calculate Training_Time.
  Trial_Beginning_Event = 0;
  Rand_Texture = 0;
  Lick_At_Correct_Port = 0;
  Fisrt_Lick_In_Response_Time = 0;
  Last_Lick_State = 0;
  Stage_Of_Trail = "It";
  GUI_Recieve(); // Send Message To GUI.
  Current_Time = millis();
  while (1) {

	if (millis() - Current_Time >= 2000) {//Send Message Every 2 Sec.
		  Lick_In_Response_Time = 0;
		  Current_Time = millis();
		  GUI_Recieve(); // Send Message To GUI.
	}

	GUI_STOP(); //Stop Tranning.
	if (Command == 'S')
		goto STOP;

    if(Lick_Check_For_Other_Trannings() == 2 || Lick_Check_For_Other_Trannings() == 1){
    
			  //Count Timer - Doing Something In set time:
			  Current_Time_Tone = millis();
			  Current_Time = millis();  //Current Time For Time Stamp Timer.
			  Current_Time_Water = millis();
			//Response Timer - Count Timer - Doing Something In set time:

		    //Stage_Of_Trail = "Rr";
		   //	GUI_Recieve(); // Send Message To GUI.

			Lick_Flag = 1; //Lift Flag Up;
			Lick_In_Response_Time = 1;
			Current_Time = millis();
			  while (millis() - Current_Time <= Response_Time) {//Response_Time==1000?
				GUI_STOP(); //Stop Tranning.
				if (Command == 'S')
				  goto STOP;

				if (Lick_Check_For_Other_Trannings());

				Play_Tone();
				//Lick_Check_For_Other_Trannings();
				Water_Process(2);
				Water_Process(1);
			  }
			  Lick_In_Response_Time = 0;
			  Stage_Of_Trail = "It";
			  GUI_Recieve(); // Send Message To GUI.

			  Current_Time_Vaccum = millis();
			  while (millis() - Current_Time_Vaccum <= Vacuum_Duration)
				Vaccum_Process();

			  Stage_Of_Trail = "It";
			  Current_Time = millis();
    }
  }

  //END Of Trials:
  Trial_Beginning_Event = 2;
  //GUI_Recieve();
    STOP:;

}


// For training stage 2 : Association between S1 to R1, and S2 to R2.
void Training_Stage_2(){

  Turn_Stepper(ON);
  delay(5);
  while (digitalRead(Home_Switch)) //until the sensor receive the arm it moves.
    Stepper_Reset();
  //First Time Texture Selection:
  Rand_Texture = 2;
  delay(10);
  Show_Texture2();
  Stepper_Movement1(); //Start The Fisrt Trial Only After Stepper Move.
  GUI_STOP(); //Stop Tranning.
  if (Command == 'S')
    goto STOP;
  Stage_Of_Trail = "It";
  Lick_At_Correct_Port = 0;
  Start_Training_Time = millis(); //For Calculate Training_Time.
  GUI_Recieve(); // Send Message To GUI.
  //Number Of Trials Loop:
  for (Actual_Trials = 1; Actual_Trials <= Number_Of_Trials; Actual_Trials++) {
    //Number Of Select Loop(3 to each select):
	  Rand_Texture = 2;
	  Show_Texture2();
    //For S1:
    for (Actual_Repeats = 1; Actual_Repeats <= Number_Of_Repeats; Actual_Repeats++) {
      //Sample_Duration - Count Timer - Doing Something In set time:
      Stepper_Movement_Flag = 0;
      Trial_Beginning_Event = 1;
	  Punishment_Counter = 0;
	  Last_Lick_State = 0;
      Stage_Of_Trail = "Sa";
      GUI_Recieve(); // Send Message To GUI.
      Trial_Beginning_Event = 0;
      Current_Time = millis();  //Current Time For Time Stamp Timer. 
      while (millis() - Current_Time <= Sample_Duration) {
        GUI_STOP(); //Stop Tranning.
        if (Command == 'S')
          goto STOP;
        //If Lick Match Open Valve:
		Stage_Of_Trail = "Rr";
        switch (Lick_Match()) {
			
			Stage_Of_Trail = "Sa";

			case 0: {
			  Lick_At_Correct_Port = 2;//If not match .
			  GUI_Recieve(); //Send Message After Lick;
			  break;
			}

			case 1: {
			  Lick_At_Correct_Port = 1;
			  GUI_Recieve(); //Send Message After Lick.
			  //Count Timer - Doing Something In set time:
			  Current_Time_Tone = millis();
			  Current_Time_Water = millis();
			  WaterFlag = 1;
			  break;
			}

			case 2: {
			  Lick_At_Correct_Port = 1;
			  GUI_Recieve(); //Send Message After Lick.
			  //Count Timer - Doing Something In set time:
			  Current_Time_Tone = millis();
			  Current_Time_Water = millis();
			  WaterFlag = 2;
			  break;
			}
			case -1: {
			  Lick_At_Correct_Port = 0;//Non Lick.
			  break;
			}
        }

        if (WaterFlag == 1) {
          Play_Tone();
          Water_Process(1);
        }
        if(WaterFlag == 2){
          Play_Tone();
          Water_Process(2);
        }
      }
      Close_Solenoid(Water_Valve1);
      Close_Solenoid(Water_Valve2);
      Rand_Texture = 2;
      if (Actual_Repeats == Number_Of_Repeats)
        Rand_Texture = 1;
      Show_Texture2();
      Stage_Of_Trail = "It";
	  Punishment_Counter = 0;
      GUI_Recieve(); // Send Message To GUI.
      Current_Time = millis();  //Current Time For Time Stamp Timer.
      Current_Time_Vaccum = Current_Time;  //Current Time For Time Stamp Timer.
      Current_Time_Servo = Current_Time;
	  Last_Lick_State = 0;
      while (millis() - Current_Time <= Inter_Trial_Interval) {

        GUI_STOP(); //Stop Tranning.
        if (Command == 'S')
          goto STOP;

        Vaccum_Process();
        Stepper_Reset();
		switch (Lick_Match()) {

		case 0: {
			Lick_At_Correct_Port = 2;//If not match .
			GUI_Recieve(); //Send Message After Lick;
			break;
		}
		case 1: {
			Lick_At_Correct_Port = 1;
			GUI_Recieve(); //Send Message After Lick.
			break;
		}
		case 2: {
			Lick_At_Correct_Port = 1;
			GUI_Recieve(); //Send Message After Lick.
			break;
		}
		case -1: {
			Lick_At_Correct_Port = 0;//Non Lick.
			break;
		}
		}
	  
        //if (Stepper_Movement_Flag)
       //   Stepper_Movement();
      //  if (Actual_Step == End_Steps)
        //  break;
      }
	  Stepper_Movement1(); //Movement Outside Of IT Time - Add About 1 Sec To The IT TIME.
    }

	//Again Now For S2 :
	Rand_Texture = 1;
	delay(10);
	Show_Texture2();
	delay(100);
    Stage_Of_Trail = "It";
    GUI_Recieve(); // Send Message To GUI.
    for (Actual_Repeats = 1; Actual_Repeats <= Number_Of_Repeats; Actual_Repeats++) {
      //Sample_Duration - Count Timer - Doing Something In set time:
      Stepper_Movement_Flag = 0;
      Trial_Beginning_Event = 1;
	  Punishment_Counter = 0;
	  Last_Lick_State = 0;
      Stage_Of_Trail = "Sa";
      GUI_Recieve(); // Send Message To GUI.
      Trial_Beginning_Event = 0;
      Current_Time = millis();  //Current Time For Time Stamp Timer. 
      while (millis() - Current_Time <= Sample_Duration) {
        GUI_STOP(); //Stop Tranning.
        if (Command == 'S')
          goto STOP;
        //If Lick Match Open Valve: 
		Stage_Of_Trail = "Rr";
		switch (Lick_Match()) {

		Stage_Of_Trail = "Sa";

        case 0: {
          Lick_At_Correct_Port = 2;//If not match .
          GUI_Recieve(); //Send Message After Lick;
          break;
        }

        case 1: {
          Lick_At_Correct_Port = 1;
          GUI_Recieve(); //Send Message After Lick.
          //Count Timer - Doing Something In set time:
          Current_Time_Tone = millis();
          Current_Time_Water = millis();
          WaterFlag = 1;
          break;
        }

        case 2: {
          Lick_At_Correct_Port = 1;
          GUI_Recieve(); //Send Message After Lick.
          //Count Timer - Doing Something In set time:
          Current_Time_Tone = millis();
          Current_Time_Water = millis();
          WaterFlag = 2;
          break;
        }
        case -1: {
          Lick_At_Correct_Port = 0;//Non Lick.
          break;
        }
        }

        if (WaterFlag == 1) {
          Play_Tone();
          Water_Process(1);
        }
        else {
          Play_Tone();
          Water_Process(2);
        }
      }
      Close_Solenoid(Water_Valve1);
      Close_Solenoid(Water_Valve2);
      Rand_Texture = 1;
      if (Actual_Repeats == Number_Of_Repeats)
        Rand_Texture = 2;
      Show_Texture2();
      Stage_Of_Trail = "It";
      GUI_Recieve(); // Send Message To GUI.
      Current_Time = millis();  //Current Time For Time Stamp Timer.
      Current_Time_Vaccum = Current_Time;  //Current Time For Time Stamp Timer.
      Current_Time_Servo = Current_Time;
	  Last_Lick_State = 0;
      while (millis() - Current_Time <= Inter_Trial_Interval) {
        GUI_STOP(); //Stop Tranning.
        if (Command == 'S')
          goto STOP;
		Vaccum_Process();
		Stepper_Reset();

		switch (Lick_Match()) {

		case 0: {
			Lick_At_Correct_Port = 2;//If not match .
			GUI_Recieve(); //Send Message After Lick;
			break;
		}
		case 1: {
			Lick_At_Correct_Port = 1;
			GUI_Recieve(); //Send Message After Lick.
			break;
		}
		case 2: {
			Lick_At_Correct_Port = 1;
			GUI_Recieve(); //Send Message After Lick.
			break;
		}
		case -1: {
			Lick_At_Correct_Port = 0;//Non Lick.
			break;
		}
		}
     //   if (Stepper_Movement_Flag)
     //     Stepper_Movement();
        if (Actual_Step == End_Steps)
          break;

      }
	  Stepper_Movement1(); //Movement Outside Of IT Time - Add About 1 Sec To The IT TIME.
    }
  }

  //END Of Trials:
  Trial_Beginning_Event = 2;
  GUI_Recieve();
  //Turn_Stepper(OFF);
  STOP:;

}

//For training stage 3 : �Water delivered only after the first lick that follows the tone�.
void Training_Stage_3() {


  Turn_Stepper(ON);
  delay(5);
  while (digitalRead(Home_Switch))
    Stepper_Reset();
  //First Time Texture Selection:
  Create_Random_Movement();
  Show_Texture1();
  Stepper_Movement1(); //Start The Fisrt Trial Only After Stepper Move.
  GUI_STOP(); //Stop Tranning.
  if (Command == 'S')
    goto STOP;
  Start_Training_Time = millis(); //For Calculate Training_Time.
  Stage_Of_Trail = "It";
  Lick_At_Correct_Port = 0;
  Fisrt_Lick_In_Response_Time = 0;
  GUI_Recieve(); // Send Message To GUI.
  //Number Of Trials Loop:
  for (Actual_Trials = 1; Actual_Trials <= Number_Of_Trials; Actual_Trials++) {
    //Sample_Duration - Count Timer - Doing Something In set time:
    Stepper_Movement_Flag = 0;
    Trial_Beginning_Event = 1;
    Stage_Of_Trail = "Sa";
    GUI_Recieve(); // Send Message To GUI.
    Trial_Beginning_Event = 0;
    Current_Time = millis();  //Current Time For Time Stamp Timer. 
    while (millis() - Current_Time <= Sample_Duration) {
      GUI_STOP(); //Stop Tranning.
      if (Command == 'S')
        goto STOP;
      //If Lick Match Open Valve: 
      switch (Lick_Match()) {

      case 0: {
        Lick_At_Correct_Port = 2;//If not match .
        GUI_Recieve(); //Send Message After Lick;
        break;
      }
      case 1: {
        Lick_At_Correct_Port = 1;
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case 2: {
        Lick_At_Correct_Port = 1;
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case -1: {
        Lick_At_Correct_Port =0;//Non Lick.
        break;
      }
      }
    }
    //Response Timer - Count Timer - Doing Something In set time:
    Stage_Of_Trail = "Rr";
    GUI_Recieve(); // Send Message To GUI.
    Current_Time = millis();  //Current Time For Time Stamp Timer.
    Lick_Flag = 1; //Lift Flag Up;
    Lick_In_Response_Time = 1;
    Current_Time_Tone = millis();//Current Time For Time Stamp Timer.
    Current_Time_Water = millis();
    while (millis() - Current_Time <= Response_Time) {
      GUI_STOP(); //Stop Tranning.
      if (Command == 'S')
        goto STOP;
      Play_Tone();
      Stepper_Reset();
      //If Lick Match Open Valve: 
      switch (Lick_Match()) {

      case 0: {
        Lick_At_Correct_Port =2;//If not match .
        GUI_Recieve(); //Send Message After Lick;
        Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
        Punishment();
        Stage_Of_Trail = "Rr";
		GUI_Recieve(); //Send Message After Lick;
        break;
      }
      case 1: {
        WaterFlag = 1;
        Lick_At_Correct_Port = 1;
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case 2: {
        WaterFlag = 2;
        Lick_At_Correct_Port = 1;
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case -1: {
        Lick_At_Correct_Port = 0;//Non Lick.
        break;
      }
      }

      if (WaterFlag == 1) {
        Water_Process(1);
      }
	  if (WaterFlag == 2) {
        Water_Process(2);
      }

    }
    Close_Solenoid(Water_Valve1);
    Close_Solenoid(Water_Valve2);
    Stage_Of_Trail = "It";
    GUI_Recieve(); // Send Message To GUI.
    Current_Time = millis();  //Current Time For Time Stamp Timer.
    Current_Time_Vaccum = Current_Time;  //Current Time For Time Stamp Timer.
    Current_Time_Servo = Current_Time;
    while (millis() - Current_Time <= Inter_Trial_Interval) {
      GUI_STOP(); //Stop Tranning.
      if (Command == 'S')
        goto STOP;
      Vaccum_Process();
      //Show_Texture();
   //   if (Stepper_Movement_Flag)
    //    Stepper_Movement();
      if (Actual_Step == End_Steps)
        break;
      //If Lick Match Open Valve: 
      switch (Lick_Match()) {

      case 0: {
        Lick_At_Correct_Port = 2;//If not match .
        Stage_Of_Trail = "It";
		GUI_Recieve(); //Send Message After Lick;
        break;
      }
      case 1: {
        Lick_At_Correct_Port = 1;
        Stage_Of_Trail = "It";
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case 2: {
        Lick_At_Correct_Port = 1;
        Stage_Of_Trail = "It";
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case -1: {
        Lick_At_Correct_Port = 0;//Non Lick.
        break;
      }
      }
    }
	Create_Random_Movement();
	Show_Texture1();
	Stepper_Movement1(); //Movement Outside Of IT Time - Add About 1 Sec To The IT TIME.
  }

  //END Of Trials:
  Trial_Beginning_Event = 2;
  GUI_Recieve();
  //Turn_Stepper(OFF);
   STOP:;
}

//For training stage 4: the full training (discrimination).
void Training_Stage_4() {

  Turn_Stepper(ON);
  delay(5);
  while(digitalRead(Home_Switch))
    Stepper_Reset();
  //First Time Texture Selection:
  Create_Random_Movement();
  Show_Texture1();
  Stepper_Movement1(); //Start The Fisrt Trial Only After Stepper Move.
  GUI_STOP(); //Stop Tranning.
  if (Command == 'S')
    goto STOP;
  Start_Training_Time = millis(); //For Calculate Training_Time.
  //Number Of Trials Loop:
  for (Actual_Trials = 1; Actual_Trials <= Number_Of_Trials; Actual_Trials++) {
    //Sample_Duration - Count Timer - Doing Something In set time:
    Stepper_Movement_Flag = 0;
    Trial_Beginning_Event = 1;
    Stage_Of_Trail = "Sa";
    GUI_Recieve(); // Send Message To GUI.
    Trial_Beginning_Event = 0;
    Current_Time = millis();  //Current Time For Time Stamp Timer. 
	Punishment_Counter = 0;
    while (millis() - Current_Time <= Sample_Duration) {
      GUI_STOP(); //Stop Tranning.
      if (Command == 'S')
        goto STOP;
      //If Lick Match Open Valve: 
      switch (Lick_Match()) {

      case 0: {
        Lick_At_Correct_Port = 2; //If not match.
        GUI_Recieve(); //Send Message After Lick;
        Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
        Punishment();
        Stage_Of_Trail = "Sa";
		GUI_Recieve(); //Send Message After Lick;
        break;
      }
      case 1: {
        Lick_At_Correct_Port = 1;
		GUI_Recieve(); //Send Message After Lick;
        Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
        Punishment();
        Stage_Of_Trail = "Sa";
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case 2: {
        Lick_At_Correct_Port = 1;
		GUI_Recieve(); //Send Message After Lick;
        Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
        Punishment();
        Stage_Of_Trail = "Sa";
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case -1: {
        Lick_At_Correct_Port = 0;//Non Lick.
        break;
      }
      }
    }
    //Retention Timer - Count Timer - Doing Something In set time: 
    Stage_Of_Trail = "Re";
    GUI_Recieve(); // Send Message To GUI.
	Punishment_Counter = 0;
    Current_Time = millis();  //Current Time For Time Stamp Timer.
    while (millis() - Current_Time <= Retention_Duration) {
      GUI_STOP(); //Stop Tranning.
      if (Command == 'S')
        goto STOP;
      Stepper_Reset();
      //If Lick Match Open Valve: 
      switch (Lick_Match()) {

      case 0: {
        Lick_At_Correct_Port = 2;//If not match .
        GUI_Recieve(); //Send Message After Lick;
        Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
        Punishment();
        Stage_Of_Trail = "Re";
		GUI_Recieve(); //Send Message After Lick;
        break;
      }
      case 1: {
        Lick_At_Correct_Port = 1;
		GUI_Recieve(); //Send Message After Lick;
        Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
        Punishment();
        Stage_Of_Trail = "Re";
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case 2: {
        Lick_At_Correct_Port = 1;
		GUI_Recieve(); //Send Message After Lick;
        Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
        Punishment();
        Stage_Of_Trail = "Re";
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case -1: {
        Lick_At_Correct_Port = 0;//Non Lick.
        break;
      }
      }
    }
    //Response Timer - Count Timer - Doing Something In set time:
    Stage_Of_Trail = "Rr";
    GUI_Recieve(); // Send Message To GUI.
    Current_Time = millis();  //Current Time For Time Stamp Timer.
    Lick_Flag = 1; //Lift Flag Up;
    Lick_In_Response_Time = 1; 
	Punishment_Counter = 0;
    Current_Time_Tone = millis();//Current Time For Time Stamp Timer.
    while (millis() - Current_Time <= Response_Time) {
      GUI_STOP(); //Stop Tranning.
      if (Command == 'S')
        goto STOP;
	  Stepper_Reset();
      Play_Tone();
      //If Lick Match Open Valve: 
      switch (Lick_Match()) {

      case 0: {
        Lick_At_Correct_Port = 2;//If not match .
        GUI_Recieve(); //Send Message After Lick;
        break;
      }
      case 1: {
        WaterFlag = 1;
        Lick_At_Correct_Port = 1;
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case 2: {
        WaterFlag = 2;
        Lick_At_Correct_Port = 1;
        GUI_Recieve(); //Send Message After Lick.
        break;
      }
      case -1: {
        Lick_At_Correct_Port = 0;//Non Lick.
        break;
      }
      }

      if (WaterFlag == 1) {
        Water_Process(1);
      }
	  if (WaterFlag == 2) {
        Water_Process(2);
      }

    }

    Close_Solenoid(Water_Valve1);
    Close_Solenoid(Water_Valve2);
    Create_Random_Movement();
    Stage_Of_Trail = "It";
    GUI_Recieve(); // Send Message To GUI.
    Current_Time = millis();  //Current Time For Time Stamp Timer.
    Current_Time_Vaccum = Current_Time;  //Current Time For Time Stamp Timer.
    Current_Time_Servo = Current_Time;
	Punishment_Counter = 0;
    while (millis() - Current_Time <= Inter_Trial_Interval) {
      GUI_STOP(); //Stop Tranning.
      if (Command == 'S')
        goto STOP;
      Vaccum_Process();
      Show_Texture();
   //   if(Stepper_Movement_Flag)
     //   Stepper_Movement();
        //If Lick Match Open Valve: 
        switch (Lick_Match()) {

        case 0: {
          Lick_At_Correct_Port = 2;//If not match .
          GUI_Recieve(); //Send Message After Lick;
          Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
          Punishment();
          Stage_Of_Trail = "It";
		  GUI_Recieve(); //Send Message After Lick;
          break;
        }
        case 1: {
          Lick_At_Correct_Port = 1;
		  GUI_Recieve(); //Send Message After Lick;
          Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
          Punishment();
          Stage_Of_Trail = "It";
          GUI_Recieve(); //Send Message After Lick.
          break;
        }
        case 2: {
          Lick_At_Correct_Port = 1;
		  GUI_Recieve(); //Send Message After Lick;
          Current_Time += Punishment_Duration; // After punishment Inter_Trial continue.
          Punishment();
          Stage_Of_Trail = "It";
          GUI_Recieve(); //Send Message After Lick.
          break;
        }
        case -1: {
          Lick_At_Correct_Port = 0;//Non Lick.
          break;
        }
        }
       }
	  Stepper_Movement1(); //Movement Outside Of IT Time - Add About 1 Sec To The IT TIME.
  }

  //END Of Trials:
  Trial_Beginning_Event = 2;
  GUI_Recieve();
 // Turn_Stepper(OFF);
  STOP:;
}

//Create An Random Movement: *This function must be called before every trail.
void Create_Random_Movement() {

  //Create An Random Circles:
  Rand_Circle = random(5, 8);
  //Create An Random Angle:
  for (int i = 1; i <= Rand_Circle; i++) {
    Rand_Angle[i] = random(1, 4); //from 1-5.
    Rand_Angle[i] = map(Rand_Angle[i], 1, 3, 60, 180);
  }

  Current_Circle = 1;//Return it to 1 so Random Movement will be executed.

  //Create An Random Texture:
  Rand_Texture = random(1, 3); // 1 or 2.

  Texture_Flag = 1; //Lift the flag up so Random Texture can move one time at trail.

}


//Move Random The Servo(M2) Angle And Choose Random Texture (Multitasking):
void Show_Texture() {

  if (Current_Circle <= Rand_Circle) {
    if (millis() - Current_Time_Servo >= Move_Servo_Duration) {
      Current_Time_Servo = millis();
      //Create An Random Movement:
      Servo1.write(Rand_Angle[Current_Circle]);
      Current_Circle++;
    }
  }
    else
      if (Texture_Flag) {//Lift the flag up so Random Texture can move one time at trail.

        Texture_Flag = 0;

        if (Rand_Texture == 1)
          Servo1.write(Texture1_Angle);
        else
          Servo1.write(Texture0_Angle);

        Stepper_Movement_Flag = 1; //To Start Stepper In 'ITI' Only After The Servo Move.
      }
}

//Move Random The Servo(M2) Angle And Choose Random Texture (In Order) :
void Show_Texture1() {

  //Move Servo Randomaly From 5 To 10 (Max):
  for (int i = 1; i <= Rand_Circle; i++) {
    Servo1.write(Rand_Angle[i]);
    delay(100);
  }
  if (Rand_Texture == 1)
    Servo1.write(Texture1_Angle);
  else
    Servo1.write(Texture0_Angle);
  delay(50);
}

//Move Random The Servo(M2) Angle And Choose Texture (In Order) :
void Show_Texture2() {

  if (Rand_Texture == 1)
    Servo1.write(Texture1_Angle);
  else
    Servo1.write(Texture0_Angle);
  delay(50);
}

void Servo_Reset(){

//No Need Yet.
}

//Check Is it first Lick event within the response time :
void Check_Fisrt_Lick_In_Response_Time() {

  if (Lick_Flag) {

    Fisrt_Lick_In_Response_Time = 1;
    Lick_Flag = 0; //Lift Flag Up;
  }
  else
    Fisrt_Lick_In_Response_Time = 0;
}

void Check_Lick_In_Response_Time(){

if (!Stage_Of_Trail.compareTo("Rr"))
Lick_In_Response_Time = 1;
else
Lick_In_Response_Time = 2;

}


//Check Lick And Send It To The Computer For Other Trannings 2 ,3:
int Lick_Check_For_Other_Trannings() {

  if (!digitalRead(Lick1)) {  //Check if one licked.
    Check_Lick_In_Response_Time();
    Check_Fisrt_Lick_In_Response_Time();
	Lick_In_Response_Time = 1;
    if (Last_Lick_State == 0) {//Debounce for lick - Send Lick only 1 Time When Lick Occurred.
      Last_Lick_State = 1;
	  Stage_Of_Trail = "Rr";
      GUI_Recieve(); // Send Message To GUI.
	  Lick_In_Response_Time = 0;
      return 1;
    }
  }
  else
    if (!digitalRead(Lick2)) { //Check if two licked.
      Check_Lick_In_Response_Time();
      Check_Fisrt_Lick_In_Response_Time();
	  Lick_In_Response_Time = 2;
      if (Last_Lick_State == 0) {//Debounce for lick - Send Lick only 1 Time When Lick Occurred.
        Last_Lick_State = 1;
		Stage_Of_Trail = "Rr";
        GUI_Recieve(); // Send Message To GUI.
		Lick_In_Response_Time = 0;
        return 2;
      }
    }
    else {
      Last_Lick_State = 0;
      return 0; //Non lick.
    }
}

//Check Lick And Send It To The Computer:
int Lick_Check(){ 
  
  if (!digitalRead(Lick1)) {  //Check if one licked.
    Check_Lick_In_Response_Time();
    Check_Fisrt_Lick_In_Response_Time();
    if (Last_Lick_State == 0) {//Debounce for lick - Send Lick only 1 Time When Lick Occurred.
      Last_Lick_State = 1;
      return 1;
    }
	else
		return 0; //Non lick.
  }
  else 
    if (!digitalRead(Lick2)) { //Check if two licked.
      Check_Lick_In_Response_Time();
      Check_Fisrt_Lick_In_Response_Time();
      if (Last_Lick_State == 0) {//Debounce for lick - Send Lick only 1 Time When Lick Occurred.
        Last_Lick_State = 1;
        return 2;
      }
	  else
		  return 0; //Non lick.
    }
    else {
      Last_Lick_State = 0;
      return 0; //Non lick.
    }
  
}

//Check if The Lick Match The Texture (For Training Stage 2,3,4):
int Lick_Match() {

  int Lick = Lick_Check();

  //5 Modes Possibles:
  if (Lick == 0) {
    Lick_In_Response_Time = 0;
    return -1; //Non Lick.
  }
  else 
    if (Lick == 1 && Rand_Texture == 1)//Texture 1.
      return 1;
    else
      if (Lick == 2 && Rand_Texture == 2) //Texture 2.
        return 2;
      else
        if (Lick == 1 && Rand_Texture == 2) //Incorrect.
          return 0;
        else
          if (Lick == 2 && Rand_Texture == 1) //Incorrect.
            return 0;

}

void Open_Solenoid(byte Solenoid_Pin){

    digitalWrite(Solenoid_Pin,HIGH);
}

void Close_Solenoid(byte Solenoid_Pin){

    digitalWrite(Solenoid_Pin,LOW);

}

//Water_Process - Start Water (Multitasking Process):
void Water_Process(int num) {

  if(num==1)
    Close_Solenoid(Water_Valve2);
  if (num == 2)
    Close_Solenoid(Water_Valve1);

  if (millis() - Current_Time_Water >= Water_Duration) {
    Close_Solenoid(Water_Valve1);
    Close_Solenoid(Water_Valve2);
	WaterFlag = 0;
  }
  else {
    if (num == 1)
      Open_Solenoid(Water_Valve1);
    if (num == 2)
      Open_Solenoid(Water_Valve2);
  }
}


//Vaccum_Process - Start Vacuum (Multitasking Process):
void Vaccum_Process() { 

  if (millis() - Current_Time_Vaccum >= Vacuum_Duration){
    Close_Solenoid(Vacuum_Valve1);
    Close_Solenoid(Vacuum_Valve2);
  }
  else {
    Open_Solenoid(Vacuum_Valve1);
    Open_Solenoid(Vacuum_Valve2);
  }
}

//Auditory Cue Process (Multitasking Process):
void Play_Tone() {


  if (millis() - Current_Time_Tone >= Tone_Duration)
    noTone(Speaker);
  else
    tone(Speaker, freq);

  //tone(pin, frequency, duration);
}

//Carrousel Speed In r.p.m:
void CarrouselSpeed() {

  Carrousel_Speed = analogRead(Carrousel_Speed_Pin);
  Carrousel_Speed = map(Carrousel_Speed, 0, 1023, 0, 400);
}

/* 
void INTERRUPT_SETUP() {

  pinMode(FlowPin, INPUT); //initializes digital pin 2 as an input
  attachInterrupt(4, Flow_INTERRUPTS, RISING); //and the interrupt is attached
}
void Flow_INTERRUPTS()     //This is the function that the interupt calls 
{
  Signal_Flow++;  //This function measures the rising and falling edge of the hall effect sensors signal
}

void WaterFlow() {//Calculate Flow.

  Signal_Flow = 0;      //Set NbTops to 0 ready for calculations
  sei();            //Enables interrupts
  delay(100);      //Wait 1 second
           //cli(); 
  detachInterrupt(19);//Disable interrupts
  Flow = (Signal_Flow * 60 / 7.5) * 10; //(Pulse frequency x 60) / 7.5Q, = flow rate in L/hour 
} */

//Stepper Motor Functions (M1):
//-----------------------------

//Turn Stepper On/Off:
void Turn_Stepper(boolean state1) {

  if (state1) {
    // Turn Stepper_Module On:
    digitalWrite(StepperOff, HIGH);//Turn Motor Driver On.
    delay(5);
  }
  else {
    // Turn Stepper_Module Off:
    digitalWrite(DIR, LOW);
    digitalWrite(STEP, LOW);
    digitalWrite(StepperOff, LOW);
  }

}

//Stepper_Reset (Multitasking Process) :
void Stepper_Reset(){
  //Move Stepper To Home Position.
  if(digitalRead(Home_Switch))
    Stepper_Steps(-1, Stepper_Speed);
    Actual_Step = 0; //Zero The Angle Counter.
}

//Stepper_Movement (Multitasking Process) :
void Stepper_Movement() {
  //Move Stepper To The End Degree.
  if (Actual_Step < End_Steps) {
    Stepper_Steps(1, Stepper_Speed);
    Actual_Step++;
  }
}

//Stepper_Movement (In Order) :
void Stepper_Movement1() {
  //Move Stepper To The End Degree.
  while (Actual_Step < End_Steps) {
    Stepper_Steps(1, Stepper_Speed);
    Actual_Step++;
  }
}

//Rotate With Steps : 
void Stepper_Steps(int steps, float speed){ 
  //rotate a specific number of microsteps (8 microsteps per step)
  //- (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger.
  int dir = (steps > 0)? HIGH:LOW;
  steps = abs(steps);

  digitalWrite(DIR,dir); 

  float usDelay = (1 / speed) * 80;

  for(int i=0; i < steps; i++){ 
    digitalWrite(STEP, HIGH); 
    delayMicroseconds(usDelay); 

    digitalWrite(STEP, LOW); 
    delayMicroseconds(usDelay); 
  } 
} 


/* OLD STEPPER FUNCTION - NOT MULTITASKING*/
/*

//200 Steps are 360 Degrees (Module:A4988).
//StepperOff --> THE ENABLE PIN ON 4988 MODULE.
//------------------
// Turn Stepper_Module On:
digitalWrite(StepperOff,HIGH);//Turn Motor Driver On.
delay(5);

// Turn Stepper_Module Off:
digitalWrite(DIR, LOW);
digitalWrite(STEP, LOW);
digitalWrite(StepperOff,LOW);
//------------------
//Put in define :
#define ON 1
#define OFF 0
//Turn Stepper On/Off:
void Turn_Stepper(boolean state1) {

if (state1) {
// Turn Stepper_Module On:
digitalWrite(StepperOff, HIGH);//Turn Motor Driver On.
delay(5);
}
else {
// Turn Stepper_Module Off:
digitalWrite(DIR, LOW);
digitalWrite(STEP, LOW);
digitalWrite(StepperOff, LOW);
}

}
//------------------

//Rotate With Angle:
void Stepper_Degree(float deg, float speed) {
  //rotate a specific number of degrees (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger.
  int dir = (deg > 0) ? HIGH : LOW;
  digitalWrite(DIR, dir);

  int steps = abs(deg)*(1 / 0.225);
  float usDelay = (1 / speed) * 70;

  for (int i = 0; i < steps; i++) {
    digitalWrite(STEP, HIGH);
    delayMicroseconds(usDelay);

    digitalWrite(STEP, LOW);
    delayMicroseconds(usDelay);
  }
}
//Rotate With Steps:
void Stepper_Steps(int steps, float speed) {
  //rotate a specific number of microsteps (8 microsteps per step)
  //- (negitive for reverse movement)
  //speed is any number from .01 -> 1 with 1 being fastest - Slower is stronger.
  int dir = (steps > 0) ? HIGH : LOW;
  steps = abs(steps);

  digitalWrite(DIR, dir);

  float usDelay = (1 / speed) * 70;

  for (int i = 0; i < steps; i++) {
    digitalWrite(STEP, HIGH);
    delayMicroseconds(usDelay);

    digitalWrite(STEP, LOW);
    delayMicroseconds(usDelay);
  }
}

*/



