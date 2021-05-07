
/* 
 *  Mind Control Server - for ESP8266
 *  
 *  
 * License - GPL v3
 * (C) 2021 Copyright - Gene Ruebsamen
 * ruebsamen.gene@gmail.com
 */

#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <timer.h>

#define DDRIVE_MIN -100 //The minimum value x or y can be.
#define DDRIVE_MAX 100  //The maximum value x or y can be.
#define MOTOR_MIN_PWM -1023 //The minimum value the motor output can be.
#define MOTOR_MAX_PWM 1023 //The maximum value the motor output can be.

// wired connections
#define L9110_A_IA 0 // D7 --> Motor B Input A --> MOTOR A +
#define L9110_A_IB 2 // D6 --> Motor B Input B --> MOTOR A -
 
// functional connections
#define MOTOR_A_PWM L9110_A_IA // Motor A PWM Speed
#define MOTOR_A_DIR L9110_A_IB // Motor A Direction
 
// the actual values for "fast" and "slow" depend on the motor
#define PWM_SLOW 50  // arbitrary slow speed PWM duty cycle
#define DIR_DELAY 1000 // brief delay for abrupt motor changes

#define MIN_THRESHOLD 50

//const char ssid[]="ssid_here";
//const char pass[]="password_here";
char  replyPacket[] = "Hi there! Got the message :-)";  // a reply string to send back
WiFiUDP udp;
unsigned int localPort = 10000;
const int PACKET_SIZE = 256;
char packetBuffer[PACKET_SIZE];
int status = WL_IDLE_STATUS;
int prev_S=128;
auto timer = timer_create_default();
bool firing = false;


void coast() {
  //Serial.println( "Soft stop (coast)..." );
  digitalWrite( MOTOR_A_DIR, LOW );
  digitalWrite( MOTOR_A_PWM, LOW );
}

void brake() {
  Serial.println( "Hard stop (brake)..." );
  digitalWrite( MOTOR_A_DIR, HIGH );
  digitalWrite( MOTOR_A_PWM, HIGH );
}

int LeftMotorOutput;
int RightMotorOutput;

void calcTankDrive(float x, float y)
{
  float rawLeft;
  float rawRight;
  float RawLeft;
  float RawRight;

  // first compute angle in deg
  // first hypotenuse
  float z = sqrt(x*x+y*y);

  // angle in radians
  float rad = acos(abs(x) / z);

  // handle NaN
  if (isnan(rad) == true) {
    rad = 0;
  }

  // degrees
  float angle = rad * 180/ PI;
  // Now angle indicates the measure of turn
  // Along a straight line, with an angle o, the turn co-efficient is same
  // this applies for angles between 0-90, with angle 0 the co-eff is -1
  // with angle 45, the co-efficient is 0 and with angle 90, it is 1

  float tcoeff = -1 + (angle / 90) * 2;
  float turn = tcoeff * abs(abs(y) - abs(x));
  turn = round(turn * 100) / 100;

  // And max of y or x is the movement
  float mov = _max(abs(y), abs(x));

  // First and third quadrant
  if ((x >= 0 && y >= 0) || (x < 0 && y < 0))
  {
    rawLeft = mov; rawRight = turn;
  }
  else
  {
    rawRight = mov; rawLeft = turn;
  }

  // Reverse polarity
  if (y < 0) {
    rawLeft = 0 - rawLeft;
    rawRight = 0 - rawRight;
  }

  // Update the values
  RawLeft = rawLeft;
  RawRight = rawRight;

  // Map the values onto the defined rang
  LeftMotorOutput = map(rawLeft, DDRIVE_MIN, DDRIVE_MAX, MOTOR_MIN_PWM, MOTOR_MAX_PWM);
  RightMotorOutput = map(rawRight, DDRIVE_MIN, DDRIVE_MAX, MOTOR_MIN_PWM, MOTOR_MAX_PWM);
}

bool taser_stop(void *) {
  firing = false;
  //digitalWrite(TASERPIN, LOW);
  return true; // repeat? true
}

void taser(int shockTime) {
  if (!firing) {
    //digitalWrite(TASERPIN, HIGH);
    timer.in(shockTime*1000,taser_stop);
    firing = true;
  }
}


IPAddress local_IP(192,168,1,205);
IPAddress gateway(192,168,1,1);
IPAddress subnet(255,255,255,0);

void setup() {
  
  Serial.begin(115200);
  Serial.begin(115200);
  Serial.println();

  // Setup Soft AP
  Serial.print("Setting soft-AP configuration ... ");
  Serial.println(WiFi.softAPConfig(local_IP, gateway, subnet) ? "Ready" : "Failed!");

  Serial.print("Setting soft-AP ... ");
  Serial.println(WiFi.softAP("MindControl_AP") ? "Ready" : "Failed!");

  Serial.print("Soft-AP IP address = ");
  Serial.println(WiFi.softAPIP());
  // END SOFT AP

/* 
  // Connect to LOCAL AP
  WiFi.begin(ssid,pass);
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connected, IP address: ");
  Serial.println(WiFi.localIP());
// END LOCAL AP
*/

  //Serial.print("AP IP address: ");
 // Serial.println(myIP);
  Serial.println("Starting UDP");
  udp.begin(localPort);
  Serial.print("Local port: ");
  Serial.println(udp.localPort());

  pinMode( MOTOR_A_DIR, OUTPUT );
  pinMode( MOTOR_A_PWM, OUTPUT );
  coast();

  Serial.println("start udp read");
}
int rlen,val_V=0,val_S=128;
int  x,y;
bool debug = false;

void loop() {
  rlen = udp.parsePacket();

  if (rlen) {
    //Serial.printf("Received %d bytes from %s, port %d\n", rlen, udp.remoteIP().toString().c_str(), udp.remotePort());
  
    int len = udp.read(packetBuffer, 255);
    if (len > 0)
    {
      packetBuffer[len] = 0;
    }
    //Serial.printf("UDP packet contents: %s\n", packetBuffer);
    if (debug) {
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write(packetBuffer);
      udp.endPacket();
    }


    char *val;
    val = strtok(packetBuffer,":");
    while (val != NULL) {
      if (val[0] == 'X') {
        x = atoi(&val[1]);
      }
      else if (val[0] == 'Y') {
        y = atoi(&val[1]);
      }
      else if (val[0] == 'T') {
        // tail
        int num = atoi(&val[1]);
        taser(num);
        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.write("fire taser");
        udp.endPacket();
        //yield();
      }
      else if (val[0] == 'D') {
        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        debug = !debug;
        if (debug)
          udp.write("Debug ON\n");
         else 
          udp.write("Debug OFF\n");
        udp.endPacket();
      }
      val = strtok(NULL,":");
    }
    //x = atof(packetBuffer);

    //calcTankDrive(x,y);
    yield();  
    //Serial.printf("L: %d, R: %d\n",LeftMotorOutput,RightMotorOutput);
    int mapx = map(x, -100, 100, -1023, 1023);
    Serial.printf("x_val: %d\n",mapx);
    if (mapx > MIN_THRESHOLD) {
      digitalWrite( MOTOR_A_DIR, LOW ); // direction = forward (HIGH)
      analogWrite( MOTOR_A_PWM, mapx ); // PWM speed = slow      
    } else if (mapx < MIN_THRESHOLD) {
      analogWrite( MOTOR_A_DIR, -mapx ); // direction = forward (HIGH)
      digitalWrite( MOTOR_A_PWM, LOW ); // PWM speed = slow            
    } else {
      digitalWrite( MOTOR_A_DIR, LOW ); // direction = forward (HIGH)
      digitalWrite( MOTOR_A_PWM, LOW ); // PWM speed = slow                  
    }      
  }
  timer.tick();
}
