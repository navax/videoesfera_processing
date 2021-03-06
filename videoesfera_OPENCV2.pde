//
//  ___________________________________________________________________________________*
//  
//   VIDEOESFERA+OPENCV  12/2016
//  
//   paulocosta@usp.br
//  
//  ___________________________________________________________________________________*
//

// tecla <F> - display fps
// tecla <S> - wireframe
// tecla <1...> pontos textura
//
//

import processing.video.*;            
import gab.opencv.*; //https://github.com/atduskgreg/opencv-processing
import java.awt.Rectangle;

//
OpenCV opencv;
PImage src, colorFilteredImage;
ArrayList<Contour> contours;
int rangeLow = 160; //  ----matiz de cor parâmetros openCV
int rangeHigh = 190;
Rectangle cvBox;
//
PImage img;                           
int texW, texH;                      
Movie myMovie;                      
//
int numPointsW;                       
int numPointsH;                       
int numPointsH_2pi; 
int ptsW, ptsH;                       
//
float[] coorX;                        
float[] coorY;
float[] coorZ;
float[] multXZ;
float[][] uvtext;                    
//
float raio;                           
float cx, cy, cz;                     
float targetX, targetY, targetZ;      
//
int searchU, searchV;
float changeU;                        
float changeV;                       
boolean isTexture;                  
//                                        
PShape videoesfera;                  
PVector targetVertex;                 
//                                     
int fcount, lastm;
float frate;
int fint = 3;
//
PVector targetLoc;
PVector camVelo;
PVector camAcelera;
PVector camLoc;
float maxf;
float maxspd;
boolean isTranslate;
//
float hpX, hpY, hpZ;
// 
float longitude;                       
float latitude;                        
float savedX;                          
float savedY;                          
float savedLat;                       
float savedLong;                       
boolean controleMouse;               
//
boolean kp;                           
boolean isFPS;                       
boolean isStroke;
boolean isSpot;
boolean isSpin;
//
int fpsrate=999;
//
PGraphics planoText;
PGraphics centerText;
PGraphics hotSpot;
//
PShape plano;
PShape camBox;
boolean isLabel;

//
//
// setup  ------------------------------------
//
//

void setup() {                         
  //
  size(1600, 900, P3D); //-------------------------->
  frameRate(fpsrate);
  imageMode(CENTER);
  textureMode(NORMAL);
  //
  opencv = new OpenCV(this, 1600, 900);// ----------------------------->
  contours = new ArrayList<Contour>();
  //
  //img=loadImage("frame360.png");
  //
  // myMovie = new Movie(this, "paramotor.mp4");
  myMovie = new Movie(this, "rpk.mov");
  myMovie.loop();
  //
  texW=1600; // ---------------------------------------> largura video
  texH=900;  // ---------------------------------------> altura video
  //
  longitude=0.0;
  latitude=0.0;
  //
  ptsW=128;
  ptsH=128;
  raio=200.0;
  float chu=texW/(float)(ptsW); 
  float chv=texH/(float)(ptsH/2);
  changeU=map(chu, 0, texW, 0, 1);       
  changeV=map(chv, 0, texH, 0, 1);      
  //
  initializeSphere(ptsW, ptsH);         
  esferaTextura();                     
  //
  cx=float(width/2);
  cy=float(height/2);
  cz=(cy) / tan(PI*80.0 / 180.0);
  targetX=0;
  targetY=0;
  targetZ=0;
  //
  planoText=createGraphics(200, 100, P3D);
  centerText=createGraphics(200, 200, P3D);
  infoTextura("", color (255, 0, 0, 100));
  infoTarget();
  //
  camAcelera=new PVector(0, 0); 
  camVelo= new PVector (0, 0);  
  targetLoc=new PVector (0, 0); 
  camLoc= new PVector(0, 0);
  maxf=10.0;                      
  maxspd=2.0;                     
  isTranslate=false;
  //
  isLabel=false;
  //
  kp=false;
  isFPS=false;
  controleMouse=false;
  isStroke=true;
  isSpot=false;
  isSpin=false;
}
//
// movieEvent ------------------------------------
//
void movieEvent(Movie m) {                                                                      
  m.read();
} 

//
//
// draw ------------------------------------
//
//

void draw() { 
  background(255);
  //
  autoTranslate();
  cameraControl();  
  openCVColor();
  searchHotSpot(cvBox);
  //
  camera(cx, cy, (cy) / tan(PI*80.0 / 180.0), cx+targetX, cy+targetY, targetZ, 0, 1, 0);        
  shape(videoesfera, cx, cy);
  //
  drawOverlays();
  autoSpin();
}

//
// openCVColor ------------------------------------
//
void openCVColor() {
  opencv.loadImage(myMovie);
  opencv.useColor();
  src = opencv.getSnapshot();
  opencv.useColor(HSB);
  opencv.setGray(opencv.getH().clone());  
  opencv.inRange(rangeLow, rangeHigh);
  colorFilteredImage = opencv.getSnapshot();
  contours = opencv.findContours(true, true);
  if (contours.size() > 0) {
    Contour biggestContour = contours.get(0);
    cvBox = biggestContour.getBoundingBox();
  }
}
//
// searchHotSpot  ------------------------------------
//
//
void searchHotSpot(Rectangle boundBox) {
  targetVertex=videoesfera.getVertex (searchVertex(boundBox.x, boundBox.y));
  PVector ptcam=new PVector(targetX, targetY, targetZ);
  PVector trajeto=PVector.sub(targetVertex, ptcam);
  float distToSpot=trajeto.mag();
  //println(d);
  if (distToSpot < 70.00) {
    isSpot=true;
    infoTextura("Alvo", color (0, 0, 255, 100));
  } else {
    isSpot=false;
  }
}
//
// drawOverlays ------------------------------------
//
void drawOverlays() {
  
  hint(DISABLE_DEPTH_TEST);
  
  camera();
  image(centerText, width/2, height/2);
  
  
  if (isLabel) {
    image(planoText, width/2, height/2-100);
  }
  
  if (isSpot) {
    image (planoText, width/2, height/2-100);
  }
  
  if (isFPS) {                                                                                 
    fpsCount();
  }
  
  hint(ENABLE_DEPTH_TEST);
}
//
// autoSpin ------------------------------------
//
void autoSpin() {
  if (!controleMouse && isSpin) {                                                                      
    longitude+=0.1;
  }
}
//
// autoTranslate ------------------------------------
//
void autoTranslate() {
   if (isTranslate) {
    transCam(targetLoc);
    updateTrans();
    latitude=pixelToLat(camLoc.y);
    longitude=pixelToLong(camLoc.x);
  }
}
//
// initializeSphere ------------------------------------
// baseado no código  Gillia Ramsay - https://processing.org/examples/texturesphere.html
//
void initializeSphere(int numPtsW, int numPtsH_2pi) {
  numPointsW=numPtsW+1;
  numPointsH_2pi=numPtsH_2pi; 
  numPointsH=ceil((float)numPointsH_2pi/2)+1;  
  //
  coorX=new float[numPointsW];   
  coorY=new float[numPointsH];   
  coorZ=new float[numPointsW];  
  multXZ=new float[numPointsH];  
  //
  for (int i=0; i<numPointsW; i++) {                                                       
    float thetaW=i*2*PI/(numPointsW-1);
    coorX[i]=sin(thetaW);
    coorZ[i]=cos(thetaW);
  }
  //
  for (int i=0; i<numPointsH; i++) {  
    if (int(numPointsH_2pi/2) != (float)numPointsH_2pi/2 && i==numPointsH-1) {               
      float thetaH=(i-1)*2*PI/(numPointsH_2pi);                                               
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=0;
    } else {
      float thetaH=i*2*PI/(numPointsH_2pi);
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=sin(thetaH);
    }
  }
  //
  videoesfera=createShape();                                                                   
  videoesfera.beginShape(TRIANGLE_STRIP);
  if (isStroke) {
    videoesfera.stroke(0);
  } else {
    videoesfera.noStroke();
  }
  // looping escrever vértices
  for (int i=0; i<(numPointsH-1); i++) {                                                       
    float coory=coorY[i];                                                                      
    float cooryPlus=coorY[i+1];                                                                
    float multxz=multXZ[i];                                                                    
    float multxzPlus=multXZ[i+1];                                                                             
    for (int j=0; j<numPointsW; j++) { 
      //videoesfera.normal(-coorX[j]*multxz, -coory, -coorZ[j]*multxz);
      videoesfera.vertex(coorX[j]*multxz*raio, coory*raio, coorZ[j]*multxz*raio);               
      //videoesfera.normal(-coorX[j]*multxzPlus, -cooryPlus, -coorZ[j]*multxzPlus);
      videoesfera.vertex(coorX[j]*multxzPlus*raio, cooryPlus*raio, coorZ[j]*multxzPlus*raio);
    }
  }
  //
  videoesfera.endShape();
  videoesfera.setTextureMode(NORMAL);
}
//
// esferaTextura  ------------------------------------
//
void esferaTextura() {
  float u=0.0;                                                                
  float v=0.0;
  int stripLength=ptsW+ptsH+2;                                                
  int vertexNumber=videoesfera.getVertexCount ();                             
  int utexel;                                                               
  int vtexel;
  //
  uvtext=new float [vertexNumber] [2];                                        
  //
  videoesfera.setTexture((myMovie));                                         
  //
  for (int i = 0; i < vertexNumber; i++) {                                   
    if (i%2==0) {
      videoesfera.setTextureUV(i, u, v);                                     
      utexel=(int) map(u, 0, 1, 0, texW);                                     
      vtexel=(int) map(v, 0, 1, 0, texH);
      uvtext[i][0]=utexel;                                                   
      uvtext[i][1]=vtexel;
    } else {                                                                 
      videoesfera.setTextureUV(i, u, v+changeV);
      utexel=(int) map(u, 0, 1, 0, texW);
      vtexel=(int) map(v+changeV, 0, 1, 0, texH);                           
      uvtext[i][0]=utexel;
      uvtext[i][1]=vtexel;
      u+=changeU;
    }
    if (((i+1)%stripLength)==0) {
      u=0.0;
      v+=changeV;
    }
  }
}
//
// searchVertex  ------------------------------------
//        
int searchVertex (float tu, float tv) {                                       
  float distmin=texW/(float)(ptsW);                                           
  int vertIndex=0;
  for (int i=0; i<uvtext.length; i++) {                                       
    float calcdist=dist(tu, tv, uvtext[i][0], uvtext[i][1]);
    if (calcdist<distmin) {
      distmin=calcdist;
      vertIndex=i;
    }
  }
  return (vertIndex);
}
//
// pixelToLong  ------------------------------------
//
float pixelToLong (float px) {
  float ptlong=0.0;
  if (texW>0) {
    ptlong=(px*360.0)/texW;
  }
  return (ptlong);
}
//
// pixelToLat  ------------------------------------
//
float pixelToLat (float py) {
  float ptlat=0.0;
  if (texH>0) {
    ptlat=(py*180.0)/texH;
  }
  return(ptlat);
}
//
// longToPixel ------------------------------------
//
float longToPixel (float lg) {
  float px;
  px=(texW*lg)/360;
  return px;
}
//
// latToPixel ------------------------------------
//
float latToPixel (float lt) {
  float px;
  px=(texH*lt)/180;
  return px;
}
//
// cameraControl  ------------------------------------
//
void cameraControl() {
  //latitude=max(-85,min(85,latitude));
  targetX=raio*(sin(radians(longitude))*sin(radians(latitude)));          
  targetY=raio*cos (radians(latitude)+PI);                                
  targetZ=raio*(cos(radians(longitude))*sin(radians(latitude)));
}
//
// transCam  ------------------------------------
//
void transCam (PVector target) { // target - targetLoc
  PVector trajeto=PVector.sub (target, camLoc);
  float d=trajeto.mag();
  if (d<100) {
    float m= map(d, 0, 100, 0, maxspd);
    trajeto.setMag(m);
  } else {
    trajeto.setMag(maxspd);
  }
  PVector redireciona= PVector.sub(trajeto, camVelo);
  redireciona.limit(maxf);
  camAcelera.add(redireciona);
  if (d<10.0) {
    isLabel=true;
  }
  //println(d);
}
//
// updateTrans  ------------------------------------
//
void updateTrans() {
  camVelo.add(camAcelera);
  camVelo.limit(maxspd);
  camLoc.add(camVelo);
  camAcelera.mult(0);
  //println (camLoc);
}
//
// updateCamLoc  ------------------------------------
//
void updateCamLoc() {
  camLoc.x=longToPixel(longitude);
  camLoc.y=latToPixel(latitude);
}
//
// fpsCount  ------------------------------------
//
void fpsCount() {                                                         
  hint(DISABLE_DEPTH_TEST);
  fcount += 1;
  int m = millis();
  if (m - lastm > 1000 * fint) {
    frate = float(fcount) / fint;
    fcount = 0;
    lastm = m;
    println("fps: " + frate);
  }
  hint(ENABLE_DEPTH_TEST);
}
//
// TECLADO   ------------------------------------
//
//
void keyPressed() { 
  isLabel=false;
  updateCamLoc();
  //
  if (key =='1') {
    targetLoc.x=1532.0;
    targetLoc.y=355.0;
    isTranslate=true;
    infoTextura(str(key), color (255, 0, 0, 100));
  }
  //
  if (key =='2') {
    targetLoc.x=461.0;
    targetLoc.y=673.0;
    isTranslate=true;
    infoTextura(str(key), color (0, 0, 255, 100));
  }

  if (key =='3') {
    targetLoc.x=550.0;
    targetLoc.y=217.0;
    isTranslate=true;
    infoTextura(str(key), color (0, 255, 0, 100));
  }
}

//
// info texturas  ------------------------------------
//
void infoTextura(String msg, color cor) {
  planoText.beginDraw();
  planoText.smooth();
  planoText.background(cor);
  planoText.noStroke();
  planoText.fill(255);
  planoText.textSize(24);
  planoText.text(msg, 100, 50, 0);
  planoText.endDraw();
}
//
void infoPlano() {
  plano.beginShape(QUAD);
  plano.noStroke();
  plano.texture(planoText);
  plano.vertex (cx+0, cy+0, -50, 0, 0);
  plano.vertex (cx+100, cy+0, -50, 1, 0);
  plano.vertex(cx+100, cy+100, -50, 1, 1);
  plano.vertex(cx+0, cy+100, -50, 0, 1);
  plano.endShape();
}
//
void infoTarget() {
  centerText.beginDraw();
  centerText.background(255, 0);
  centerText.smooth();
  centerText.strokeWeight(3);
  centerText.stroke(0, 110);
  centerText.fill(255, 50);
  centerText.ellipse(100, 100, 100, 100);
  centerText.strokeWeight(1);
  centerText.ellipse(100, 100, 20, 20);
  centerText.endDraw();
}
//
void infoHotSpot() {
  hotSpot=createGraphics(cvBox.width, cvBox.height, P3D);
  hotSpot.beginDraw();
  hotSpot.background(0, 100);
  hotSpot.endDraw();
}
//
// MOUSE   ------------------------------------
//
void mouseDragged() {
  if (controleMouse) {
    //println(longitude);
    longitude=(savedX-mouseX)*0.1+savedLong;
    latitude=(mouseY-savedY)*0.1+savedLat;
  }
}
// 
void mouseReleased() {
  controleMouse=false;
}
//
void mousePressed() {
  isTranslate=false;
  isLabel=false;
  controleMouse=true;
  savedX=mouseX;
  savedY=mouseY;
  savedLong=longitude;
  savedLat=latitude;
}