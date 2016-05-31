#include <IRremote.h>
//
////For the remote controller
////for IR
#define RECV_PIN  9
#define SPEED_PIN 11
IRrecv irrecv(RECV_PIN);
decode_results results;
#define S1   A1
#define S2   A2
#define S3   A3
#define S4   A4
#define S5   A5
#define CLP  53
#define VEL 50
#define VELM1 6
#define VELM2 7
#define M11  25
#define M12  24
#define M21  23
#define M22  22
#define THRESHOLD 100
#define FRONT    1
#define DER      2
#define IZQ      3
#define STOP     4
#define NORMAL   5
#define CERRADO  6
#define BACK     7
  
int s1val, s2val, s3val, s4val, s5val, diract, clp;
int inByte=-1;
int cruce= 0;
int stopByte=0;
void setup(){
   Serial.begin(9600);
  
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  irrecv.enableIRIn(); // Start the receiver
  //while(Serial.available() == 0);
   
  
 pinMode(S1, INPUT);
 pinMode(S2, INPUT);
 pinMode(S3, INPUT);
 pinMode(S4, INPUT);
 pinMode(S5, INPUT);
 pinMode(CLP, INPUT);
 pinMode(M11, OUTPUT);
 pinMode(M21, OUTPUT);
 pinMode(M12, OUTPUT);
 pinMode(M22, OUTPUT);
 pinMode(SPEED_PIN, OUTPUT);
 
 pinMode(VELM2, OUTPUT);
 pinMode(VELM1, OUTPUT);
analogWrite(VELM1,VEL);
analogWrite(VELM2,VEL);
analogWrite(SPEED_PIN, 180);
 digitalWrite(M11,LOW); //Paramos los motores por precaucion
 digitalWrite(M21,LOW);
 digitalWrite(M12,LOW); //Paramos los motores por precaucion
 digitalWrite(M22,LOW);
   Serial.write("config\n");
        
while(inByte == -1){
   inByte = readFromRemote(); 
   Serial.println(inByte);
   Serial.println("  plaza seleccionada\n");
    }
}
void loop(){
  
  s1val = analogRead(S1);
    Serial.print("sensor1 = ");
    Serial.println(s1val);
  s2val = analogRead(S2);
  
    Serial.print("sensor2 = ");
  Serial.println(s2val);
  s3val = analogRead(S3);
    Serial.print("sensor3 = ");
  Serial.println(s3val);
  s4val = analogRead(S4);
  s5val = analogRead(S5);
    Serial.print("sensor5 = ");
  Serial.println(s5val);

  clp=digitalRead(CLP);
 
 if(stopByte==0){

 if(clp == 1){
  mover(STOP,NORMAL);
  diract=STOP;
  stopByte=1;
 }

  
 if(s3val<THRESHOLD){ //Si el sensor central ve la linea
  Serial.write("s3 activado   ");
   mover(FRONT,NORMAL);
   diract=FRONT;
 }else if(s2val<THRESHOLD){ //Sensor derecho 
  Serial.write("s2 activado   ");
   mover(IZQ,NORMAL);
   diract=IZQ;
 }else if (s4val<THRESHOLD){
  Serial.write("s4 activado   ");
   mover(DER,NORMAL);
   diract=DER;
 }else if(s1val<THRESHOLD){//Sensor del extremo 
  Serial.write("s1 activado   ");
   mover(IZQ,CERRADO);
   diract=IZQ;
 }else if (s5val<THRESHOLD){
  Serial.write("s5 activado   ");
   mover(DER,CERRADO);  
   diract=DER;
 }

 
 
 if(s1val<THRESHOLD && s2val<THRESHOLD && s3val<THRESHOLD && s4val<THRESHOLD && s5val<THRESHOLD){ //Todos los sensores sobre una sup negra

  if(inByte==1 && cruce==0){
    mover(IZQ,CERRADO);  
   diract=IZQ;
   delay(100);
  }else if(inByte==2 && cruce==1){
    mover(IZQ,CERRADO);  
   diract=IZQ;
    delay(300);
  }else if(inByte==3 && cruce==1){
    mover(DER,CERRADO);  
   diract=DER;
    delay(300);
  }else if(inByte==4 && cruce==0){
    mover(DER,CERRADO);  
   diract=DER;
    delay(100);
  }else{
    mover(diract,NORMAL);
       Serial.println("palante\n");
  }
   cruce=1;
   delay(200);
 }
 if(s1val>THRESHOLD && s2val>THRESHOLD && s3val>THRESHOLD && s4val>THRESHOLD && s5val>THRESHOLD){ //Todos los sensores sobre una sup blanca
   mover(BACK,NORMAL);
       Serial.println("continuando un poco\n");
   }
 
 delay(200);
 
 }else{
  mover(STOP,NORMAL);
   diract=STOP;
 }


  if(clp == 1){
  mover(STOP,NORMAL);
  diract=STOP;
  stopByte=1;
 }

 
}
void mover(int dir, int mode){
 
 switch (dir){
 
  case STOP:
   digitalWrite(M11,LOW); 
   digitalWrite(M12,LOW); 
   digitalWrite(M21,LOW);
   digitalWrite(M22,LOW); 
      Serial.write("stop    ");
  break;
  
  case FRONT:   
  digitalWrite(M11,LOW); 
   digitalWrite(M12,HIGH); 
   digitalWrite(M21,HIGH);
   digitalWrite(M22,LOW); 
      Serial.write("front    ");
  break;
 
  case IZQ:
        Serial.write("izq    ");
    if(mode == NORMAL){
         digitalWrite(M11,LOW); 
   digitalWrite(M12,HIGH); 
   digitalWrite(M21,LOW);
   digitalWrite(M22,LOW);
    }else{
   digitalWrite(M11,LOW); 
   digitalWrite(M12,HIGH); 
   digitalWrite(M21,LOW);
   digitalWrite(M22,HIGH);
    }
  break;
 
  case DER:
        Serial.write("der    ");
  if(mode == NORMAL){
    digitalWrite(M11,LOW); 
   digitalWrite(M12,LOW); 
   digitalWrite(M21,HIGH);
   digitalWrite(M22,LOW);
    }else{
   digitalWrite(M11,HIGH); 
   digitalWrite(M12,LOW); 
   digitalWrite(M21,HIGH);
   digitalWrite(M22,LOW);      
    }
    break; 
     case BACK:
       digitalWrite(M11,HIGH); 
       digitalWrite(M12,LOW); 
       digitalWrite(M21,LOW);
       digitalWrite(M22,HIGH);
    break; 
 }
 
}
// 
//
//
////take in IR remote and only output the ints
int readFromRemote(){
  String button_pressed = "0";
  int button_number;
  int result = 10;
  //loop until get an input from the remote
   while(result>9){
      if (irrecv.decode(&results)) // have we received an IR signal?
      {
          button_pressed = translateIR(); 
          irrecv.resume(); // receive the next value         
          result = button_pressed.toInt();
      }
  }
  return result;
}
///////////////////////////////////////////////////////////////////////////////
//
String translateIR() // takes action based on IR code received
//
//// describing Car MP3 IR codes 
//
{
//
  switch(results.value)
//
  {
        Serial.println("ta aqui");
    Serial.println(results.value);
//
  case 0xFFA25D:  
    return("10Power"); 
    break;
//
  case 0xFF629D:  
    return("11Mode"); 
    break;
//
  case 0xFFE21D:  
    return("12Mute/UnMute"); 
   break;
//
  case 0xFF22DD:  
    return("13PREV"); 
    break;
//
  case 0xFF02FD:  
    return("14NEXT"); 
    break;
//
  case 0xFFC23D:  
    return("15PLAY/PAUSE"); 
    break;
//
  case 0xFFE01F:  
    return("16VOL-"); 
    break;
//
  case 0xFFA857:  
    return("17VOL+"); 
    break;
  case 0xFF906F:  
    return("18EQ"); 
    break;
//
  case 0xFF6897:  
    return("0"); 
    break;
//
  case 0xFF9867:  
    return("100Plus"); 
    break;
//
  case 0xFFB04F:  
    return("19Return"); 
    break;
//
  case 0xFF30CF:  
    return("1"); 
    break;
//
  case 0xFF18E7:  
    return("2"); 
    break;
//
  case 0xFF7A85:  
   return("3"); 
    break;
//
  case 0xFF10EF:  
    return("4"); 
    break;
//
 case 0xFF38C7:  
    return("5"); 
    break;
//
  case 0xFF5AA5:  
    return("6"); 
    break;
//
  case 0xFF42BD:  
    return("7"); 
    break;
//
  case 0xFF4AB5:  
    return("8"); 
    break;
//
  case 0xFF52AD:  
    return("9"); 
    break;
//
  default: 
    return(" 20other button   ");    
    Serial.println(results.value, HEX );
//
//
  }
//
//
  delay(500);
//
//
}
//
  
// 
//
