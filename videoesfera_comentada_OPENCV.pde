//
//  ___________________________________________________________________________________*
//  
//   VIDEOESFERA  11/2016
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
import gab.opencv.*;
import java.awt.Rectangle;
OpenCV opencv;
ArrayList <Contour> contornos;
import processing.video.*;            // lib video (Processing)


PImage img;                           // imagem para textura (estática)
int texW, texH;                       // dimensões da textura
Movie myMovie;                        // vídeo (textura)



int numPointsW;                       // dimensão array coordenadas  para cálculo vértice (distribuicao horizontal)
int numPointsH;                       // dimensão array coordenadas  para cálculo vértice (distribuicao vertical)
int numPointsH_2pi; 
int ptsW, ptsH;                       // quantidade de vertices horizontais  e verticais


float[] coorX;                        // arrays armazenamento coordenadas  pontos da esfera
float[] coorY;
float[] coorZ;
float[] multXZ;
float[][] uvtext;                     // array

//
float raio;                           // raio esfera
float cx, cy, cz;                     // posição camera (olho)
float targetX, targetY, targetZ;      // centro da cena

//
int searchU, searchV;
float changeU;                        // dimensão do fragmento UV
float changeV;                        // dimensão do fragmento UV
boolean isTexture;                    // falg se textura carregada


//                                        
PShape videoesfera;                    // shape container esfera
PVector targetVertex;                  // vertex busca

//                                     //contador de frame rate
int fcount, lastm;
float frate;
int fint = 3;

// 
float longitude;                       // angulo rotação  - atualização centro  cena em cameraControl()
float latitude;                        // angulo elevação - atualização centro  cena em cameraControl()
float savedX;                          // buffer mouseX
float savedY;                          // buffer mouseY
float savedLat;                        // buffer latitude
float savedLong;                       // buffer longitude
boolean controleMouse;                 // flag se controle por mouse ativo

//
boolean kp;                            // flag tecla pressionada
boolean isFPS;                         // flag exibir fps
boolean isStroke;                       // flag desenhar wireframe

//
int fpsrate=999;                        // fps



//
//
// setup  ------------------------------------
//
//

void setup() {                         // inicialização
  size(1600, 800, P3D);
  frameRate(fpsrate);
  img=loadImage("frame360.png");
  myMovie = new Movie(this, "rpk.mov");
  myMovie.loop();
  texW=1600; // -----> largura video
  texH=900;  // -----> altura video
  
  opencv = new OpenCV(this, 1600, 900);
  opencv.startBackgroundSubtraction(1, 2, 0.5);

  //
  longitude=0.0;
  latitude=0.0;

  //
  ptsW=128;
  ptsH=128;
  raio=200.0;
  float chu=texW/(float)(ptsW); 
  float chv=texH/(float)(ptsH/2);
  changeU=map(chu, 0, texW, 0, 1);       //cálculo do incremento para criação do mapa de textura
  changeV=map(chv, 0, texH, 0, 1);       //cálculo do incremento para criação do mapa de textura

  //
  initializeSphere(ptsW, ptsH);          // CONSTRUÇÃO DOS VÉRTICES DA ESFERA  (PSHAPE)
  esferaTextura();                       // aplicação da textura (feed vídeo) 

  //
  cx=float(width/2);
  cy=float(height/2);
  cz=(cy) / tan(PI*80.0 / 180.0);
  targetX=0;
  targetY=0;
  targetZ=0;

  //
  kp=false;
  isFPS=true;
  controleMouse=false;
  isStroke=false;
}

//
//
// movieEvent ------------------------------------
//
//
//

void movieEvent(Movie m) {                                                                       // leitura frame video
  m.read();
} 


//
//
// draw ------------------------------------
//
//
//

void draw() { 
  background(255);
 hint(DISABLE_DEPTH_TEST);
  searchContour();
  if (kp) {                                                                                      // se tecla pressionada - atualização centro da cena
    targetX=targetVertex.x;
    targetY=targetVertex.y;
    targetZ=targetVertex.z;
    kp=false;
  }
 
  cameraControl();                                                                              // atualização  centro da cena baseada em movimento mouse
  camera(cx, cy, (cy) / tan(PI*80.0 / 180.0), cx+targetX, cy+targetY, targetZ, 0, 1, 0);  // camera
  shape(videoesfera, cx, cy);                                                                   // desenho esfera
  if (!controleMouse) {                                                                         // incremento longitude  rotação automática
    longitude+=0.1;
  }

  //
    hint(ENABLE_DEPTH_TEST);
  if (isFPS) {                                                                                  // display fps
    fpsCount();
  }
  
}

//
//
// initializeSphere ------------------------------------
// baseado no código  Gillia Ramsay - https://processing.org/examples/texturesphere.html
//
//

void initializeSphere(int numPtsW, int numPtsH_2pi) {
  numPointsW=numPtsW+1;
  numPointsH_2pi=numPtsH_2pi; 
  numPointsH=ceil((float)numPointsH_2pi/2)+1;  

  coorX=new float[numPointsW];   
  coorY=new float[numPointsH];   
  coorZ=new float[numPointsW];  
  multXZ=new float[numPointsH];  

  for (int i=0; i<numPointsW; i++) {                                                           // distribuição coordenadas polares  XZ
    float thetaW=i*2*PI/(numPointsW-1);
    coorX[i]=sin(thetaW);
    coorZ[i]=cos(thetaW);
  }

  for (int i=0; i<numPointsH; i++) {  
    if (int(numPointsH_2pi/2) != (float)numPointsH_2pi/2 && i==numPointsH-1) {                 // distribuição coordenada polar Y
      float thetaH=(i-1)*2*PI/(numPointsH_2pi);                                                // pólos
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=0;
    } else {
      float thetaH=i*2*PI/(numPointsH_2pi);
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=sin(thetaH);
    }
  }


  //
  videoesfera=createShape();                                                                   // criar SHAPE por TRIANGLE_STRIP
  videoesfera.beginShape(TRIANGLE_STRIP);
  if (isStroke) {
    videoesfera.stroke(0);
  } else {
    videoesfera.noStroke();
  }

  // looping escrever vértices
  for (int i=0; i<(numPointsH-1); i++) {                                                       // todos os anéis (menos pólos)
    float coory=coorY[i];                                                                      // ponto em Y
    float cooryPlus=coorY[i+1];                                                                // próximo ponto Y (zigzag)
    float multxz=multXZ[i];                                                                    // ponto em XZ
    float multxzPlus=multXZ[i+1];                                                              // próximo ponto em XZ                    
    for (int j=0; j<numPointsW; j++) { 
      //videoesfera.normal(-coorX[j]*multxz, -coory, -coorZ[j]*multxz);
      videoesfera.vertex(coorX[j]*multxz*raio, coory*raio, coorZ[j]*multxz*raio);               // VERTEX ( sin(THETA)*sin(PHI)*r,  cos (PHI+pi)*r, cos(THETA)*sin(THETA)*r)
      //videoesfera.normal(-coorX[j]*multxzPlus, -cooryPlus, -coorZ[j]*multxzPlus);
      videoesfera.vertex(coorX[j]*multxzPlus*raio, cooryPlus*raio, coorZ[j]*multxzPlus*raio);   // próximo VERTEX (zigzag)
    }
  }
  //
  videoesfera.endShape();
  videoesfera.setTextureMode(NORMAL);
}


//
//
// esferaTextura  ------------------------------------
//
//

void esferaTextura() {
  float u=0.0;                                                                // coordenadas UV da textura
  float v=0.0;
  int stripLength=ptsW+ptsH+2;                                                // quantidade total de vertices na TRIANGLE_STRIP
  int vertexNumber=videoesfera.getVertexCount ();                             // quantidade de vértices na shape esfera
  int utexel;                                                                 // coordenadas UV remapeadas
  int vtexel;
  uvtext=new float [vertexNumber] [2];                                        // buffer array para pares de UV

  videoesfera.setTexture((myMovie));                                          // vínculo da imagem de vídeo como textura da esfera

  for (int i = 0; i < vertexNumber; i++) {                                    // looping todos os vértices alternando pares e  ímpares (triangle)
    if (i%2==0) {
      videoesfera.setTextureUV(i, u, v);                                      // associa UV (fragmento) ao vértice atual
      utexel=(int) map(u, 0, 1, 0, texW);                                     // mapeamento de UV (0,1) para posição pixel na textura
      vtexel=(int) map(v, 0, 1, 0, texH);
      uvtext[i][0]=utexel;                                                    // armazena coordenadas frag textura (pixels) no buffer array
      uvtext[i][1]=vtexel;
    } else {                                                                  // mesma sequência 
      videoesfera.setTextureUV(i, u, v+changeV);
      utexel=(int) map(u, 0, 1, 0, texW);
      vtexel=(int) map(v+changeV, 0, 1, 0, texH);                             // diferença - adiciona  changeV em V (zig zag da strip)
      uvtext[i][0]=utexel;
      uvtext[i][1]=vtexel;
      u+=changeU;                                                             // incremento de referência para U (+ changeU) - horizontal
    }
    if (((i+1)%stripLength)==0) {
      u=0.0;
      v+=changeV;                                                             // incremento de referência para V (+ changeV) - VERTICAL
    }
  }
}


//
//
// searchVertex  ------------------------------------
//
//         

int searchVertex (float tu, float tv) {                                       // busca vertex baseado na coordenada da textura buscada (ponto vídeo, ou região)
  float distmin=texW/(float)(ptsW);                                           // estimula distância mínima para localizar vértice + próximo da UV
  int vertIndex=0;
  for (int i=0; i<uvtext.length; i++) {                                       // loop buffers de fragmentos textura
    float calcdist=dist(tu, tv, uvtext[i][0], uvtext[i][1]);
    if (calcdist<distmin) {
      distmin=calcdist;
      vertIndex=i;                                                            // se > distãncia mínima ,  retorna   o índice do vértice na shape
    }
  }
  return (vertIndex);
}


//
//
// pixelToLong  ------------------------------------
//
//

float pixelToLong (float px) {
  float ptlong=0.0;
  if (texW>0) {
     ptlong=(px*360.0)/texW;
  }
  return (ptlong);
}


//
//
// pixelToLat  ------------------------------------
//
//

float pixelToLat (float py) {
  float ptlat=0.0;
  if (texH>0) {
    ptlat=(py*180.0)/texH;
  }
  return(ptlat);
}


//
//
// cameraControl  ------------------------------------
//
//

void cameraControl() {
  //latitude=max(-85,min(85,latitude));
  targetX=raio*(sin(radians(longitude))*sin(radians(latitude)));          // recalcula centro cena de acordo com longitude e latitude (angulos atualizados
  targetY=raio*cos (radians(latitude)+PI);                                // para a visualização cãmera baseada nos eventos de mouse)
  targetZ=raio*(cos(radians(longitude))*sin(radians(latitude)));
}



//
//
// fpsCount  ------------------------------------
//
//

void fpsCount() {                                                         //calcula e display FPS  (se isFPS)

  fcount += 1;
  int m = millis();
  if (m - lastm > 1000 * fint) {
    frate = float(fcount) / fint;
    fcount = 0;
    lastm = m;
    println("fps: " + frate);
  }
   fill(255);
  text("fps: " + frate, cx, cy);
}


void searchContour() {
  opencv.loadImage(myMovie);
  opencv.updateBackground();
  opencv.dilate();
  opencv.erode();
  float carea=10000;
  //noFill();
  //stroke(255, 0, 0);
  //strokeWeight(3);
  for (Contour contour : opencv.findContours()) {
    if (contour.area()>carea)   {
        //println(contour.area());
        Rectangle r=contour.getBoundingBox();
        //rect (r.x,r.y,r.width,r.height);
        targetVertex=videoesfera.getVertex (searchVertex(r.x, r.y));         // busca vertex correspondente a textura         
        longitude=pixelToLong (r.x);                                           // atualiza long e lat para cameraContol                                                  
        latitude=pixelToLat (r.y);
        kp=true;
       controleMouse=false;
       //contour.draw();
    }
  }
}

//
//
// TECLADO   ------------------------------------
//
//


void keyPressed() { 

  //
  if (key =='1') {
    targetVertex=videoesfera.getVertex (searchVertex(1532.0, 355.0));         // busca vertex correspondente a textura         
    longitude=pixelToLong (1532.0);                                           // atualiza long e lat para cameraContol                                                  
    latitude=pixelToLat (355.0);
    kp=true;
    controleMouse=false;
  }

  if (key =='2') {
    targetVertex=videoesfera.getVertex (searchVertex(461.0, 673.0));              
    longitude=pixelToLong (461.0);                                                      
    latitude=pixelToLat (673.0);
    kp=true;
    controleMouse=false;
  }

  if (key =='3') {
    targetVertex=videoesfera.getVertex (searchVertex(550.0,217.0));              
    longitude=pixelToLong (550.0);                                                      
    latitude=pixelToLat (217.0);
    kp=true;
    controleMouse=false;
  }
}


//
//
// MOUSE   ------------------------------------
//
//


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
  controleMouse=true;
  savedX=mouseX;
  savedY=mouseY;
  savedLong=longitude;
  savedLat=latitude;
}