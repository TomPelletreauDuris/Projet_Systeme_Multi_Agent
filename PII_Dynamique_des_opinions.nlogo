;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     ;;;
;;; Projet informatique ;;;
;;;   individuel ENSC   ;;;
;;;   Pelletreau-Duris  ;;;
;;;         Tom         ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;



globals [
  nombre-agent-critique
  nombre-agent-naifs
  compteur-opinions-fausse
  compteur-opinions-vrai
]

breed [critiques agent-critique]
breed [naifs agent-naif]

turtles-own [
  my-neighbors
  num-neighbors
  hasno-neighbors?
  my-friend-neighbors
  num-friend-neighbors
  hasno-friend-neighbors?
  count-down-true-opinion
  count-down-fake-opinion
  True-opinion?
  Fake-opinion?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     ;;;
;;; procedure de Set-up ;;;
;;;                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  clear-all
  set nombre-agent-critique ( 0.01 * Pourcentage-critique * nombre-agent )
  set nombre-agent-naifs ( nombre-agent - nombre-agent-critique )

  create-critiques nombre-agent-critique                                    ;création des agent critiques
  [
    set shape "person"
    set color white
    setxy (random-xcor * 0.95) (random-ycor * 0.95)                         ; pour des raisons visuelles on évite de mettre les agent près des murs
    set True-opinion? false
    set Fake-opinion? false
    set hasno-neighbors? false
    set hasno-friend-neighbors? false
  ]

  create-naifs nombre-agent-naifs                                           ;création des agent naifs
  [
    set shape "person"
    set color blue
    setxy (random-xcor * 0.95) (random-ycor * 0.95)                         ; pour des raisons visuelles on évite de mettre les agent près des murs
    set True-opinion? false
    set Fake-opinion? false
    set hasno-neighbors? false
    set hasno-friend-neighbors? false
  ]

  creer-random-opinion                                                      ; distribue les opinions parmis les agents
  creer-random-network                                                      ; créer un réseau d'ami aléatoire
  ask turtles [afficher-opinion]
  ask links [afficher-lien]
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     ;;;
;;;  procedure en lien  ;;;
;;;     avec set-up     ;;;
;;;                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to creer-random-opinion                                                     ; permet de créer des opinions, mais pas besoin de randomiser sa répartition
  let compteur 0                                                            ; puisque les agents sont répartis aléatoirement dans l'univers virtuel.
  while [compteur < nombre-opinion-vrai]
  [
    ask one-of turtles
    [
      set True-opinion? true
      setup-timer-true-opinion
      set compteur-opinions-vrai compteur-opinions-vrai + 1
    ]
    set compteur compteur + 1
  ]

  set compteur 0
  while [compteur < nombre-opinion-fausse]
  [
    ask one-of turtles
    [
      set fake-opinion? true
      setup-timer-fake-opinion
      set compteur-opinions-fausse compteur-opinions-fausse + 1
    ]
    set compteur compteur + 1
  ]

  set compteur 0
end

to creer-random-network                                                      ; permet de créer des relations de façon aléatoire dans le réseau
  let n-liens round((nombre-agent - 1) * Nombre-connexion * 0.01)
  while [count links < n-liens ]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself])
                   [distance myself])
      if choice != nobody [ create-link-with choice ]
    ]
  ]
  ; make the network look a little prettier
  repeat 10
  [
    layout-spring turtles links 0.3 (world-width / (sqrt nombre-agent)) 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     ;;;
;;;   procedure de go   ;;;
;;;                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  if ticks >= 800 [stop]
  ask turtles [
    chercher-voisinnage
    move-turtles
    afficher-opinion
  ]

  tick

  ask turtles [
    decrement-timer-true-opinion
    decrement-timer-fake-opinion
    refresh-opinions
  ]
  ask links [afficher-lien]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     ;;;
;;;   procedure des     ;;;
;;;      turtles        ;;;
;;;                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to chercher-voisinnage                                                             ; faculté de perception de l'environnement proche

    set my-neighbors (other turtles) in-radius Rayon-perception                    ; les voisins sont les autres agents proches dans un rayon défini par Rayon-perception
    set num-neighbors count my-neighbors
    if (num-neighbors = 0) [set hasno-neighbors? true]
    set my-friend-neighbors (other in-link-neighbors) in-radius Rayon-perception   ; les amis voisins sont les autres agents avec qui j'ai un lien et qui sont proches dans un rayon défini par Rayon-perception
    set num-friend-neighbors count my-friend-neighbors
    if (num-friend-neighbors = 0) [set hasno-friend-neighbors? true]

end

to move-turtles                                                                     ; faculté de mouvement des agents
  let agent-naifs? false
  if (breed = naifs) [set agent-naifs? true]

  ifelse hasno-neighbors?  [move-randomly]                                          ; sans voisins, on bouge aléatoirement
  [
    ifelse hasno-friend-neighbors?                                                  ; si les voisins ne sont pas des amis, on leur donne nos opinions mais on s'aloigne d'eux que s'ils sont trop près
    [
      ifelse agent-naifs?                                                           ; cas d'un agent naif transmettant simplement les opinions
      [
        if True-opinion? [Give-neighbors-true-opinion]
        if Fake-opinion? [Give-neighbors-fake-opinion]
        move-without-friend
      ]
      [
        if True-opinion? [Give-neighbors-true-opinion]
        move-without-friend
      ]
    ]
    [
      ifelse agent-naifs?                                                           ;  cas d'un agent naif transmettant simplement les opinions
      [
        if True-opinion? [Give-neighbors-true-opinion]
        if Fake-opinion? [Give-neighbors-fake-opinion]
        move-with-friend
      ]
      [
        if True-opinion? [Give-neighbors-true-opinion]
        move-with-friend
      ]
    ]
  ]
end

to move-without-friend                                                               ; pour l'instant dirigé vers l'opposé du voisin le plus près
  let X 0
  let Y 0
  let d min [distance myself] of my-neighbors                                        ; plus petite distance me séparant d'un voisin

  ifelse (d < Rayon-distance-minimale )                                              ; on s'éloigne en prenant la direction opposée du voisin le plus près en prenant
  [                                                                                  ; les coordonées symétrique du point par rappot à l'autre
    let the-neighbor min-one-of my-neighbors [distance myself]
    ask the-neighbor [
      set X xcor
      set Y ycor
    ]
    facexy (2 * xcor - X) (2 * ycor - Y)
    forward 1
  ]
  [
    move-randomly                                                                      ; comme il n'y a pas d'ami, si le voisin est en deça de la valeur minimale on bouge aléatoirement
  ]
end

to move-with-friend                                                                  ; On essai de se rapprocher de ses amis sauf s'ils sont en deça de la valeur du rayon de distance minimale
  let X 0
  let Y 0
  let d min [distance myself] of my-friend-neighbors

  ifelse (d < Rayon-distance-minimale )                                              ; s'il sont trop près on s'éloigne de ses amis de 1
  [
    let the-neighbor min-one-of my-friend-neighbors [distance myself]
    ask the-neighbor [
      set X xcor
      set Y ycor
    ]
    facexy (2 * xcor - X) (2 * ycor - Y)
    forward 1                                                                        ; on peut s'éloigner de Rayon-distance-minimale - d ou bien de 1, au choix (1 rend les déplacement plus dynamiques)
  ]
  [
    let the-neighbor min-one-of my-friend-neighbors [distance myself]
    ask the-neighbor [
      set X xcor
      set Y ycor
    ]
    facexy (X) (Y)
    forward 1
  ]
end

to move-randomly

  right random 360
  forward 1

end

to Give-neighbors-true-opinion                                                        ; partager aux voisins les opinions vraies en fonction du taux de repoduction
  ask my-neighbors
  [
    let random-nombre random (1 / Taux-de-reproduction-opinion)
    if random-nombre = 1
    [
      ifelse True-opinion?
      [
        setup-timer-true-opinion
      ]
      [
        set True-opinion? true
        setup-timer-true-opinion
        set compteur-opinions-vrai compteur-opinions-vrai + 1
      ]
    ]
  ]
end

to Give-neighbors-fake-opinion                                                       ; partager aux voisins les opinions fake en fonction du taux de repoduction
  ask my-neighbors
  [
    let random-nombre random (1 / Taux-de-reproduction-opinion)
    if random-nombre = 1
    [
      ifelse Fake-opinion?
      [
        setup-timer-fake-opinion
      ]
      [
        set Fake-opinion? true
        setup-timer-fake-opinion
        set compteur-opinions-fausse compteur-opinions-fausse + 1
      ]
    ]
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     ;;;
;;;   procedure des     ;;;
;;;     timers et       ;;;
;;;   des compteurs     ;;;
;;;                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-timer-true-opinion
   set count-down-true-opinion Temps-retention-opinion ; a n tick timer
end

to setup-timer-fake-opinion
   set count-down-fake-opinion Temps-retention-opinion ; a n tick timer
end

to decrement-timer-true-opinion
   set count-down-true-opinion count-down-true-opinion - 1
end

to decrement-timer-fake-opinion
   set count-down-fake-opinion count-down-fake-opinion - 1
end

to-report timer-true-opinion-expired?
   report ( count-down-true-opinion <= 0 )
   set compteur-opinions-vrai compteur-opinions-vrai - 1
end

to-report timer-fake-opinion-expired?
   report ( count-down-fake-opinion <= 0 )
   set compteur-opinions-fausse compteur-opinions-fausse - 1
end

to refresh-opinions
  if timer-true-opinion-expired? [set True-opinion? false]
  if timer-fake-opinion-expired? [set Fake-opinion? false]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     ;;;
;;;     gestion de      ;;;
;;;    l'affichage      ;;;
;;;                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to afficher-opinion
  set label ""

  if Afficher-opinion?
  [
    if True-opinion?  [ set label insert-item 0 label "Vrai "  set label-color green]
    if Fake-opinion?  [ set label insert-item 0 label "Fake "  set label-color red]
    if True-opinion? and Fake-opinion? [set label-color 46]
  ]
end

to afficher-lien
  ifelse Afficher-liens? [show-link][hide-link]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                ;;;
;;;     MERCI BEAUCOUP POUR VOTRE ATTENTION        ;;;
;;;            Pelletreau-Duris Tom                ;;;
;;;                  2A - ENSC                     ;;;
;;;                                                ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
483
15
1256
789
-1
-1
15.0
1
12
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
10.0

BUTTON
16
23
79
56
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
88
24
151
57
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
161
15
244
60
NIL
count turtles
17
1
11

SWITCH
48
523
197
556
Afficher-opinion?
Afficher-opinion?
0
1
-1000

SLIDER
15
78
244
111
nombre-agent
nombre-agent
0
1000
100.0
1
1
NIL
HORIZONTAL

SLIDER
20
319
218
352
Rayon-perception
Rayon-perception
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
243
320
453
353
Rayon-distance-minimale
Rayon-distance-minimale
0
Rayon-perception
2.0
1
1
NIL
HORIZONTAL

SLIDER
263
79
443
112
Pourcentage-critique
Pourcentage-critique
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
135
408
316
441
Nombre-connexion
Nombre-connexion
0
nombre-agent * nombre-agent / 10
145.0
1
1
NIL
HORIZONTAL

SLIDER
20
246
222
279
Temps-retention-opinion
Temps-retention-opinion
0
500
50.0
10
1
tick
HORIZONTAL

SWITCH
268
523
402
556
Afficher-liens?
Afficher-liens?
0
1
-1000

SLIDER
19
184
222
217
nombre-opinion-vrai
nombre-opinion-vrai
0
nombre-agent
10.0
1
1
NIL
HORIZONTAL

SLIDER
240
184
449
217
nombre-opinion-fausse
nombre-opinion-fausse
0
nombre-agent
10.0
1
1
NIL
HORIZONTAL

PLOT
10
600
463
787
Totals des opinions
time
opinions
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"fake-opionions" 1.0 0 -2674135 true "" "plot compteur-opinions-fausse"
"true-opinions" 1.0 0 -13840069 true "" "plot compteur-opinions-vrai"

CHOOSER
239
239
452
284
Taux-de-reproduction-opinion
Taux-de-reproduction-opinion
0.1 0.05 0.01 0.005 0.001
3

TEXTBOX
268
32
436
88
Pourcentage d'agent doué de sens critique et pouvant différencier les fake-news des vraies opinions
11
0.0
1

TEXTBOX
94
137
383
171
Nombre d'opinions considérées comme vraies ou fake-news.
11
0.0
1

TEXTBOX
158
295
363
323
Propriété de perception des agents
11
0.0
1

TEXTBOX
144
156
365
184
Temps avant qu'une opinion disparaisse.
11
0.0
1

TEXTBOX
183
384
333
402
Propriété du réseau
11
0.0
1

TEXTBOX
172
494
322
512
Propriétés graphiques
11
0.0
1

TEXTBOX
1275
17
1458
283
Les agents critiques sont en blanc.\n\nLes agents naïfs sont en bleu. \n\nLes liens d'amitié entre les agents sont représentés par des traits gris. \n\nLes labels sont vert lorsqu'un agent possède une opinion \"vraie\", rouge quand c'est une \"fake-news\" et jaune lorsqu'il possède les deux.
11
0.0
1

@#$#@#$#@
## CE QUE C'EST ?

Un projet d'informatique individuel fait au sein de l'ENSC (Ecole Natioanle Supérieure de Cognitique) à Bordeaux. C'est le résultat pratique d'un travail de trois mois autour des SMA (Systèmes Multi-Agents).

## COMMENT CA MARCHE ?

Pour initialiser un modèle il faut appuyer sur "SET-UP"
Pour lancer la simulation il faut appuyer sur "GO"
Les variables fixées par défauts sont intéressantes mais il est encore plus intéressant de modifier une à une ces variables afin de regarder les effets produits sur la propagation des opinions.


## RELATED MODELS

la librairie NetLogo est très complète je vous invite à essayer les différentes simulations de la catégorie "social sciences" par exemple.

## CREDITS AND REFERENCES

"Les systèmes multi-agents : vers une intelligence collective" de Jacques Ferber
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
