#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>
#include <WebSocketsServer.h>

const int RECV_PIN = 4;
const int LED = 14;
byte currentState = HIGH;
boolean nec_ok = 0;
byte  i, nec_state = 0, command, inv_command;
unsigned int address;
unsigned long nec_code;
const char *ssid = "Mido";
const char *pass = "23011993";
uint32_t port = 80;
ESP8266WebServer server(port);
WebSocketsServer socket = WebSocketsServer(81);

const char chatPage[] PROGMEM = R"=====(
<html>
    <head>
      <style>
        #result {
          width: 80%;
          height: 500px;
          margin-left: auto;
          margin-right: auto;
          padding: 20px 50px;
          background-color: purple;
          font-size: 50px;
          font-weight: bolder;
          text-align: center;
          color: #ffff; 
        }
      </style>
    </head>
    <body>
      <textarea id="incoming"></textarea><hr/>
      <input type="text" onKeydown="sendMessage(event)" id="sending"/>
      <div id="result"></div>

      <script>
        window.onload = (e) => load();
        var incoming = document.getElementById("incoming");
        var sending = document.getElementById("sending");
        var result = document.getElementById("result");
        var socket;
        window.onload = (e) => load();
        function load() {
          socket = new WebSocket('ws://192.168.1.9:81/');
          socket.onmessage = (ev) => {
            if(ev.data == "recordConfig" || ev.data == "pauseConfig" || ev.data == "stopConfig") {
              result.innerHTML += "<h1>"+ev.data+"</h1>";
            }
            incoming.value += ev.data;
          }
        }
        function sendMessage(e) {
          if(e.keyCode == 13) {
           socket.send(sending.value);
           sending.value = ""; 
          }  
        }
      </script>
    </body>
  </html>
)=====";

void setup(){
  pinMode(RECV_PIN, INPUT_PULLUP);
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);
  Serial.begin(115200);
  
  
  Serial.println("Preparing to receive remote codes...");
  Serial.println("Get ready");
  digitalWrite(LED, !digitalRead(LED));
//  WiFi.begin(ssid, pass);
  WiFi.softAP(ssid, pass);
  IPAddress myIp = WiFi.softAPIP();
//    Serial.print("connecting to wifi");
    Serial.println("The module IP is ");
    Serial.println(myIp);
    while(WiFi.status() != WL_CONNECTED) {
      delay(200);
      Serial.print("*");    
    }
//    IPAddress ip(192, 168, 1, 200);
//    IPAddress gateway(192, 168, 1, 1);
//    IPAddress subnet(255, 255, 255, 0);
//    WiFi.config(ip, gateway, subnet);

    Serial.println(WiFi.localIP());
    Serial.print("connected to");
    Serial.print(WiFi.SSID());
    if (MDNS.begin("esp8266")) {
      Serial.println("mDNS responder started");
  } else {
      Serial.println("Error setting up MDNS responder!");
  }




    server.on("/", HTTP_GET, [](){server.send_P(200, "text/html", chatPage);});
    server.onNotFound(handleNotFound);
    server.begin();
    socket.begin();

    socket.onEvent(webSocketEvent);
    attachInterrupt(digitalPinToInterrupt(RECV_PIN), remote_read, CHANGE);
}



void welcomePage() {
  Serial.println("Welcome page");
  server.send(200, "text/html", "<h1>Mohammad Farghaly Ali Saadawy</h1>");  
}

void handleNotFound(){
  server.send(404, "text/plain", "404: Not found"); // Send HTTP status 404 (Not Found) when there's no handler for the URI in the request
}



void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload, size_t length) {
  if(type == WStype_TEXT) {
    String data = "";
    for(int i=0; i<length; i++) {
      data += char(payload[i]);
    }
    Serial.println(data);
  }
}



void loop(){
  server.handleClient();
  socket.loop();
  
  if(digitalRead(RECV_PIN) != currentState) {
//    Serial.println(currentState);
    currentState = digitalRead(RECV_PIN);
    remote_read();
    }
  if(nec_ok) {
    nec_state = 0;  
    nec_ok = 0;
    currentState = HIGH;
    address = nec_code >> 16;
    command = nec_code >> 8;
    inv_command = nec_code;
    char code[9];
//    sprintf(charBuffer, "Address is %s and  is %d and comm is %d inv is %d", address, command, inv_command);
    Serial.println((uint16_t)address, HEX);
    itoa(nec_code, code, 16);
    socket.broadcastTXT(code, sizeof(code));
  }
}


ICACHE_RAM_ATTR void remote_read() {
  unsigned int us = 0;
  //detect first 9 milliseconds of NEC
  if(nec_state == 0) {
    while(digitalRead(RECV_PIN) == LOW) {
      us++;
      delayMicroseconds(10);
    }
    if(us < 600 || us > 12000) {nec_state = 0;} else {nec_state = 1;}
    return;
  }

 //detect the next 4.5 milliseconds of NEC
 if(nec_state == 1) {
   while(digitalRead(RECV_PIN) == HIGH) {
      us++;
      delayMicroseconds(10);
    }
    if(us < 370 || us > 500) {nec_state = 0;} else {nec_state = 2;}
    return;
 }
  //detect the next 562µs of NEC
 if(nec_state == 2) {
   while(digitalRead(RECV_PIN) == LOW) {
      us++;
      delayMicroseconds(10);
    }
    if(us < 40 || us > 70) {nec_state = 0;} else {nec_state = 3;}
    return;
 }
   //detect the next 562µs or 1687µs of NEC
 if(nec_state == 3) {
   while(digitalRead(RECV_PIN) == HIGH) {
      us++;
      delayMicroseconds(10);
    }
    if(us < 40 || us > 180) {nec_state = 0;} else {
      if(us > 110) bitSet(nec_code, (31 - i));
      else bitClear(nec_code, (31 - i));
      i++;
    if(i > 31){
      nec_ok = 1;
      i = 0;
      return;
    }
    nec_state = 2;   
    }
    return;
 }
// Serial.println(nec_state);
}
