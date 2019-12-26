breed[phalenes phalene]
breed[birds bird]
breed[arbres arbre]
breed[usines usine]

patches-own[croissance cpt-crois pheromone]
phalenes-own[ctask cpt-state lover? male? lover-color]
birds-own[ctask cpt-state energy]

; tree, tree pine, flower, factory, plant, bird side egg, bug, pentagon, boat top, butterfly
to setup
  clear-all

  ask patches [
    ;set croissance 0
    ;set cpt-crois random tps-croissance-max
    ;set pcolor black
  ]

  create-phalenes nb-phalenes [
    setxy random-xcor random-ycor
    set size 4
    set lover? false
    set shape "butterfly"
    set cpt-state rand-min-max time-egg-min time-egg-max

    ifelse random-float 1 < %-male [
      set male? true
      ifelse all-states? [
        set cpt-state rand-min-max time-caterpillar-min time-caterpillar-max
        set shape "egg"
        set ctask "phalene-egg"
      ][
        set shape "butterfly"
        set ctask "phalene-male-search-female"
      ]
    ][
      set male? false
      ifelse all-states? [
        set cpt-state rand-min-max time-caterpillar-min time-caterpillar-max
        set shape "egg"
        set ctask "phalene-egg"
      ][
        set shape "butterfly"
        set ctask "phalene-female-search-tree"
      ]
    ]

    ;; TODO : C'est ici pour la couleur !
    ;; color range 0 to 9.9 (black to white)
    ;set color approximate-rgb (random 256) (random 256) (random 256);random-float 10 ;; 10 exclu

    ;set color 8 - random-float 2 ;; fait un range de 8 à 10 exclu
    ;set lover-color color

    ; TODO (en faisant simple) :
    ; L'enfant peut prendre la couleur moyenne des parents + ou - une varition de -2 à 2
    ; Les oiseaux s'attaquent UNIQUEMENT aux papillons visibles
    ; Papillons visibles = ceux pas sur un arbre
    ;                    + ceux sur un arbre mais couleurs différente de minimum 2 (ou autre valeur)

  ]

  create-birds nb-birds [
    setxy random-xcor random-ycor
    set size 8
    set color magenta
    set shape "bird side"
    set ctask "bird-hunt"

    set cpt-state rand-min-max time-bird-min time-bird-max
  ]

  create-arbres nb-arbres [
    setxy random-xcor random-ycor
    set size 10
    set shape "tree-p"
    set color 8 - random-float 2 ;; fait un range de 8 à 10 exclu
  ]

  ;; Ainsi la fonction update arbres color n'est plus appelé à la création des usines mais à chaque tick pour modifier leur valeur (du coup prends du temps à chaque tick)
  create-usines nb-usines-begin [
    setxy random-xcor random-ycor
    set size 10
    set color red
    set shape "factory"
    update-arbres-color
  ]

  reset-ticks
end

to go
  diffuse pheromone %-diffusion

  ask patches [colorate]

  ask phalenes[run ctask set cpt-state cpt-state - 1]
  ask birds[run ctask]

  ask patches [evaporate]

  tick
end

;;;;;;;;;;;;; Utiles ;;;;;;;;;;;;;

to-report rand-min-max [a b]
  report a + random abs (b - a)
end

to wiggle
  rt random 20
  lt random 20
  fd 1
end

to colorate
  set pcolor scale-color pink pheromone 1 (pheromone-max / 1.3)
end

to evaporate
  set pheromone pheromone - (pheromone * %-evaporation)
end

;;;;;;;;;;;;; Usine ;;;;;;;;;;;;;

to place-usine
  if mouse-down? [
    create-usines 1[
      setxy mouse-xcor mouse-ycor
      set size 10
      set color red
      set shape "factory"
    ]
    update-arbres-color
    stop
  ]
end

to update-arbres-color
  ask arbres [
    let u min-one-of usines [distance myself]
    if u != nobody [
      let t [distance myself] of u
      if t < tmax [
        ;; range 0 to 8 from 0 to tmax
        ;; (((OldValue - OldMin) * (NewMax - NewMin)) / (OldMax - OldMin)) + NewMin
        ;; set color ((t - 0) * (8 - 0)) / (tmax - 0) + 0
        set color (t * 8) / tmax
      ]
    ]
  ]
end

;;;;;;;;;;;;; Oiseau ;;;;;;;;;;;;;

;to keep-vital-space
;  let p min-one-of other breed in-radius birds-vital-space [distance myself]
;  if p != nobody [
;    let temp heading
;    rt random 360
;    lt random 360
;    bk birds-vital-space - distance p + 1
;    set heading temp
;  ]
;end

to bird-hunt

;  keep-vital-space
  ifelse cpt-state = 0
  [
    die
  ][
    let p min-one-of phalenes in-radius perception-birds [distance myself]

    ifelse p != nobody
    [
      ifelse [distance myself] of p < 2
      [
        ask p [die]
        set energy energy + 1
        if energy = 10
        [
          set energy 0
          hatch 1 [set cpt-state rand-min-max time-bird-min time-bird-max]
        ]
      ][
        set heading towards p
        fd 1.5
      ]
    ][
      rt random 20
      lt random 20
      fd 1.5
    ]

    set cpt-state cpt-state - 1
  ]
end

to phalene-egg
  if cpt-state = 0 [
    set cpt-state rand-min-max time-caterpillar-min time-caterpillar-max
    set shape "bug"
    set ctask "phalene-caterpillar"
  ]
end

to phalene-caterpillar
  if cpt-state = 0 [
    set cpt-state rand-min-max time-chrysalis-min time-chrysalis-max
    set shape "boat top"
    set ctask "phalene-chrysalis"
  ]
  wiggle
end

to phalene-chrysalis
  if cpt-state = 0 [
    set cpt-state rand-min-max time-butterfly-min time-butterfly-max
    set shape "butterfly"
    set ctask "phalene-chrysalis"
    ifelse male?[
      set ctask "phalene-male-search-female"
    ][
      set ctask "phalene-female-search-tree"
    ]
  ]
end

;;;;;;;;;;;;; Phalene Adulte ;;;;;;;;;;;;;

;;;;;;;;;;;;; Femelle ;;;;;;;;;;;;;

to phalene-female-search-tree

  ifelse any? arbres-here [
    set ctask "phalene-female-waiting-male"
  ][

    let a min-one-of arbres in-radius perception-phalenes [distance myself]
    ifelse a != nobody [
      set heading towards a
      fd 1
    ][
      wiggle
    ]
  ]
end

to diffuse-pheromone
  set pheromone pheromone + pheromone-max
end

to phalene-female-waiting-male
  diffuse-pheromone
end

to phalene-female-go-away
  ifelse cpt-state = 0 [
    phalene-female-lay-eggs
    ifelse one-lover-only [
      set cpt-state rand-min-max time-caterpillar-min time-caterpillar-max
      set ctask "phalene-female-wiggle-to-die"
    ][
      set ctask "phalene-female-search-tree"
    ]
  ][
    wiggle
  ]
end

to phalene-female-wiggle-to-die
  if cpt-state = 0 [
    die
  ]
  wiggle
end

to phalene-female-lay-eggs
  hatch number-childs [ ;;TODO: On peut mettre le nombre d'enfant en random sur un range (ex : entre 3 et 8 par exemple)
    set size 4
    set lover? false
    set shape "butterfly"
    set cpt-state rand-min-max time-egg-min time-egg-max

    let colorTemp ([color] of myself + [lover-color] of myself) / 2
    set colorTemp colorTemp - 2 + random-float 4 ;; prend la couleur de la MERE uniquement + ou - un random entre -2 et 2
    set colorTemp min list colorTemp 9.99 ;; max 9.99 because 10 is pitch black for another color
    set colorTemp max list colorTemp 0    ;; min 0
    set color colorTemp

    ifelse random-float 1 < %-male [
      set male? true
      ifelse all-states? [
        set cpt-state rand-min-max time-caterpillar-min time-caterpillar-max
        set shape "egg"
        set ctask "phalene-egg"
      ][
        set shape "butterfly"
        set ctask "phalene-male-search-female"
      ]
    ][
      set male? false
      ifelse all-states? [
        set cpt-state rand-min-max time-caterpillar-min time-caterpillar-max
        set shape "egg"
        set ctask "phalene-egg"
      ][
        set shape "butterfly"
        set ctask "phalene-female-search-tree"
      ]
    ]
  ]
end

;;;;;;;;;;;;; Male ;;;;;;;;;;;;;

to-report free-female-here
  report one-of other phalenes-here with [not male? and lover? = false]
end

to-report pheromone?
  report pheromone > 1
end

to follow-pheromone
  let p max-one-of neighbors [pheromone]
  set heading towards p
  fd 1
end

to phalene-male-search-female
  let f free-female-here
  ifelse f != nobody [
    if one-lover-only [
      set lover? true
      ask f [set lover? true]
    ]
    ask f [
      set cpt-state 20
      set ctask "phalene-female-go-away"
      set lover-color [color] of myself
    ]
    set cpt-state 20
    set ctask "phalene-male-go-away"
  ][
    ifelse pheromone? [
      follow-pheromone
    ][
      wiggle
    ]
  ]
end

to phalene-male-go-away
  ifelse cpt-state = 0 [
    set ctask "phalene-male-search-female"
  ][
    wiggle
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
503
10
1111
619
-1
-1
2.99
1
10
1
1
1
0
1
1
1
-100
100
-100
100
1
1
1
ticks
30.0

BUTTON
23
28
97
61
Setup
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
131
28
194
61
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
22
66
194
99
nb-phalenes
nb-phalenes
0
1000
57.0
1
1
NIL
HORIZONTAL

SLIDER
22
98
194
131
nb-birds
nb-birds
0
100
4.0
1
1
NIL
HORIZONTAL

SLIDER
40
262
212
295
time-egg-min
time-egg-min
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
40
295
212
328
time-caterpillar-min
time-caterpillar-min
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
40
328
212
361
time-chrysalis-min
time-chrysalis-min
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
42
403
214
436
%-male
%-male
0
1
0.49
0.01
1
NIL
HORIZONTAL

SLIDER
22
131
194
164
nb-arbres
nb-arbres
0
100
48.0
1
1
NIL
HORIZONTAL

SLIDER
269
48
444
81
perception-phalenes
perception-phalenes
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
269
81
444
114
perception-birds
perception-birds
0
100
33.0
1
1
NIL
HORIZONTAL

SLIDER
43
447
215
480
%-diffusion
%-diffusion
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
147
488
320
521
pheromone-max
pheromone-max
0
100
100.0
1
1
NIL
HORIZONTAL

PLOT
34
530
234
680
phalenes-population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -4699768 true "" "plot count phalenes"

PLOT
234
530
434
680
birds-population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count birds"

SLIDER
215
447
387
480
%-evaporation
%-evaporation
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
40
361
213
394
time-butterfly-min
time-butterfly-min
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
212
262
384
295
time-egg-max
time-egg-max
0
100
26.0
1
1
NIL
HORIZONTAL

SLIDER
212
295
384
328
time-caterpillar-max
time-caterpillar-max
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
212
328
384
361
time-chrysalis-max
time-chrysalis-max
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
212
361
384
394
time-butterfly-max
time-butterfly-max
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
269
114
444
147
%-detection
%-detection
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
39
201
211
234
time-bird-min
time-bird-min
0
1000
193.0
1
1
NIL
HORIZONTAL

SLIDER
211
201
383
234
time-bird-max
time-bird-max
0
1000
306.0
1
1
NIL
HORIZONTAL

SLIDER
269
146
444
179
birds-vital-space
birds-vital-space
0
100
51.0
1
1
NIL
HORIZONTAL

SLIDER
213
403
385
436
number-childs
number-childs
0
10
0.0
1
1
NIL
HORIZONTAL

SWITCH
51
702
163
735
all-states?
all-states?
1
1
-1000

SWITCH
189
702
325
735
one-lover-only
one-lover-only
0
1
-1000

BUTTON
364
699
535
732
Click to place one factory
place-usine
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
365
735
537
768
nb-usines-begin
nb-usines-begin
0
10
1.0
1
1
NIL
HORIZONTAL

PLOT
566
633
766
783
phalenes-color
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Couleur" 1.0 0 -2674135 true "" "plot mean [color] of phalenes"

PLOT
777
633
977
783
tree-color
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot mean [color] of arbres"

SLIDER
991
641
1163
674
tmax
tmax
0
500
150.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

beef
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123
Line -7500403 true 240 75 255 45
Line -7500403 true 255 45 255 90
Polygon -7500403 true true 240 75 255 30 255 90

bird side
false
0
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14

boat top
true
0
Polygon -7500403 true true 150 1 137 18 123 46 110 87 102 150 106 208 114 258 123 286 175 287 183 258 193 209 198 150 191 87 178 46 163 17
Rectangle -16777216 false false 129 92 170 178
Rectangle -16777216 false false 120 63 180 93
Rectangle -7500403 true true 133 89 165 165
Polygon -11221820 true false 150 60 105 105 150 90 195 105
Polygon -16777216 false false 150 60 105 105 150 90 195 105
Rectangle -16777216 false false 135 178 165 262
Polygon -16777216 false false 134 262 144 286 158 286 166 262
Line -16777216 false 129 149 171 149
Line -16777216 false 166 262 188 252
Line -16777216 false 134 262 112 252
Line -16777216 false 150 2 149 62

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

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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

tree-p
false
3
Circle -10899396 true false 118 3 94
Rectangle -6459832 true true 120 150 180 300
Circle -10899396 true false 65 21 108
Circle -10899396 true false 45 60 120
Circle -10899396 true false 104 44 152

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
NetLogo 6.0.4
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
