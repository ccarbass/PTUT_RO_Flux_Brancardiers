/*********************************************
 * OPL 22.1.0.0 Model
 * Author: nrogers Carbasse Pingaud
 * Creation Date: 17 avril 2023 at 10:59
 *********************************************/
 
//*------------------------------------------ Set of parameters ------------------------------------------------*//

int NbMissions = ...; // Nombre de missions
int NbMissions1 = ...; // Nombre de missions a 1 brancardier
int NbBrancardiers = ...; // Nombre de brancardiers
range N = 0..NbMissions; // Ensemble des missions y compris la mission 0 (depot)
range B = 1..NbBrancardiers; // Ensemble des brancardiers
range N0= 1..NbMissions;
range N1 = 1..NbMissions1; 			 // ensemble des missions a un brancardier
range N2 = NbMissions1+1..NbMissions; // ensemble des missions a deux brancardiers
int Hrdv[N] = ...; // Heure de rdv des missions
int Duree[N] = ...; // Duree estimee des missions
int Hdeb_mat[B] = ...; // Duree minimale des missions
int Hfin_mat[B] = ...; // Duree maximale des missions
int Hdeb_apm[B] = ...; // Duree minimale des missions
int Hfin_apm[B] = ...; // Duree maximale des missions
float TraMax[B] = ...; // tps de travail maximal d'un brancardier
float Dist[N][N] = ...; // Duree moyenne entre les missions (matrice des temps)
int M = 100000;
float R[N] = ...;

//*-------------------------------------------- Set of variables ----------------------------------------------*//
// Variables de temps

dvar boolean y[N0][B]; // Choix du brancardier k pour une mission i
dvar boolean x[N][N][B]; // Choix du brancardier k pour aller de i à j 
dvar float+ dno[N][B]; // Pointeur de sous tournee
dvar float Hdep[N][B];  //Heure de depart de la mission i pour le brancardier k
dvar float late[N][B];  // Retard sur le temps de rdv
dvar float charge[B];   // Charge temporelle des brancardiers
dvar int+  m[B];        // Nombre de mission des brancardiers


/*------------ Objective functions :Min de retard */
//

minimize ( 
 	    sum(i in N, k in B) (late[i][k]) 
         );


//*------------------------------------------- set of constraints ----------------------------------------------*//
subject to {

/*============== Definition de tournees à 1 ou 2 brancardiers ======================================*/
c1:
	forall(i in N, k in B)
	  Hdep[i][k] >= 0 ;
	  
c2 :
	forall(i in N, k in B)
	   late[i][k] >= 0;

c3 :
     forall(i in N0, k in B)
	   late[i][k] <= M* y[i][k];
	   
// Préprocesseur pour éviter les chemins dont on ne connait pas la distance
//c201:
	forall(i in N, j in N, k in B)
	   {
        if( Dist[i][j] == 900) {x[i][j][k]==0; }
	   }

// une mission j du brancardier k a un prédécesseur i
c4:
	forall(j in N0, k in B) 
	  	sum(i in N: i!=j) x[i][j][k] == y[j][k];

// une mission i du brancardier k a un successeur j  	
c5:
	forall(i in N0, k in B) 
	  	sum(j in N: i!=j) x[i][j][k] == y[i][k];
	  	
// Toute mission de N1 a un et un seul brancardier
c6:
	forall(i in N1) 
	  	sum(k in B) y[i][k] == 1;

// Toute mission de N2 a deux et seulement deux brancardiers
c7:
	forall(i in N2) 
	  	sum(k in B) y[i][k] == 2;

// Synchronisation entre les tournées à 2 brancardiers
//
// 2 chemins mènent vers une mission j a 2 brancardiers	  	

c8:
	forall(j in N2) 
	  	sum(i in N: i!=j, k in B) x[i][j][k] == sum (k in B) y[j][k];
	  	
// 2 chemins partent d''une mission i a 2 brancardiers	  
c9:
	forall(i in N2) 
	  	sum(j in N: j!=i, k in B) x[i][j][k] == sum (k in B) y[i][k];
	  	
// Tout brancardier revient à la base
c11:
	forall(k in B)
	  	sum(i in N0) x[i][0][k] == 1;

// Tout brancardier part de la base
c10:	forall(k in B)
	  	sum(j in N0) x[0][j][k] == 1;

// Pas de reflexivité sur une mission	  	
c12:   
	forall(i in N, k in B)
	  	x[i][i][k] == 0;  	 	
	  	
//Pas de sous-tournée pour chaque brancardier :  Miller-Tucker-Zemlin formulation
c13:
	forall(i in N, j in N : j>0 && j!=i, k in B )
 	dno[i][k]  + M* (x[i][j][k]-1) +2 <= dno[j][k]&&
 	dno[j][k] <= 30 ;
		  	
/*============== Maitrise de la charge de travail des brancardiers =================================*/

// Dénombrement des missions de chaque brancardier
c14: 
	forall(k in B)
		sum(i in N0) y[i][k] == m[k]; 
		
c15: 
	forall(k in B)
		 m[k] <= 20;	

// Calcul de la charge de travail de chaque brancardier
c16: 
	forall(k in B)
		sum(i in N, j in N: j != i) (Duree[i] + Dist[i][j]) * x[i][j][k] == charge[k];


//	  	Respect de la capacité de travail par la charge
c17:
	forall(k in B)
	  	charge[k] <= TraMax[k]; 		

// Chainage logique des temps de début de mission entre deux missions successives
c18:
	forall(i in N, j in N:(j!=0 && j!=i), k in B)
	  	(Hdep[i][k] + Duree[i] + Dist[i][j]) + (x[i][j][k]-1) * M <= Hdep[j][k];
	 
// Encadrement du point de rendez-vous par la tolérance de retard (R)
c19:
	forall(i in N: i!=0, k in B)
	  	(Hdep[i][k] >= Hrdv[i]*y[i][k] )
	 && (Hdep[i][k] <= (Hrdv[i] + R[i])*y[i][k]);
	 
C20:
	forall(i in N2, k1 in B, k2 in B)
	  Hdep[i][k1] <= Hdep[i][k2] + M*(1-maxl(0, y[i][k1] + y[i][k2]-1))
	  && Hdep[i][k1]+ M*(1-maxl(0, y[i][k1] + y[i][k2]-1)) >= Hdep[i][k2]  ;

// Calcul de retard de debut de mission 
c21: 
	forall(i in N0,  k in B)
	  	maxl(0 - M  *y[i][k], Hdep[i][k] - Hrdv[i] * y[i][k]) - late[i][k] == 0 ;
	  	
}

//Recuperation du nombre de trajet global
int countAll = 0;	
execute {
  for ( var i in N) {
    for ( var j in N) {
        for ( var k in B) {
          if (x[i][j][k] == 1) {
			countAll = countAll +1;
          }
        }
      }
    }
  
}  

//Creation des variables pour les resultats
range r = 1..countAll;		//creation de la liste iterable sur le nombre de trajet
int m1[r];				//liste des missions de depart
int m2[r];				//liste des missions d'arrivee
float distance[r];		// Temps de transport intermission
int bran[r];			//liste des brancardiers affectes
float hdep[r]; 			//liste des heures de depart
float hdep2[r]; 		//liste des heures de depart
int hrdv[r]; 		//liste des heures de depart
float hrdv2[r]; 		//liste des heures de depart
int hfin_mat[r]; 		//liste des heures de depart
int hdeb_apm[r]; 		//liste des heures de depart
float lateCumu;

//Titre des colones du excel
string md = "Miss_i";		
string ma = "Miss_j";	
string b = "Brancardier";
string ti = "Hdep_i";
string tj = "Hdep_j";
string hrdvi = "Hrdv_i";
string hrdvj = "Hrdv_j";
string lateC = "Retard Cumule";

//Implementation des variables 
int indice = 1;
execute{
  for ( var k in B) {
    for ( var i in N) {
      for ( var j in N) {
        if (x[i][j][k] == 1) {
          m1[indice] = i;
          m2[indice] = j;
          distance[indice]=Dist[i][j];
          bran[indice] = k;
          hdep[indice] = Hdep[i][k];
          hdep2[indice] = Hdep[j][k];
          hrdv[indice] = Hrdv[i];
          hrdv2[indice] = Hdep[i][k] + Duree[i];
          hfin_mat[indice] = Hfin_mat[k];
          hdeb_apm[indice] = Hdeb_apm[k];
          lateCumu = lateCumu + late[i][k];
          indice=indice+1;
        }
      }
    }
  }
} 

