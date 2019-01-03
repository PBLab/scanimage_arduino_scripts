//square wave with Adafruit_MCP4725 dac

#include <Wire.h>
#include <Adafruit_MCP4725.h>

Adafruit_MCP4725 dac1;
Adafruit_MCP4725 dac2;

void setup(void) {
  Serial.begin(9600);
  Serial.println("Hello!");

  // For Adafruit MCP4725A1 the address is 0x62 (default) or 0x63 (ADDR pin tied to VCC)
  // For MCP4725A0 the address is 0x60 or 0x61
  // For MCP4725A2 the address is 0x64 or 0x65
  dac1.begin(0x62); //DAC1, left side of PS box
  dac2.begin(0x63); //DAC2, right side of PS box
    
  Serial.println("Generating a triangle wave");
}

void loop(void) {
  dac1cont();
  dac2cont();
}


void dac1cont() {
  dac1.setVoltage(3000, false);  //number 0 to 4095
}
void dac2cont() {
  dac2.setVoltage(3500, false);  //number 0 to 4095
}

