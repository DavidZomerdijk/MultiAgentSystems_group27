; UVA/VU - Multi-Agent Systems
; Lecturers: T. Bosse & M.C.A. Klein
; Lab assistants: D. Formolo & L. Medeiros

; David Zomderdijk/10290745
; Maurits Bleeker/10694439
; Jorg Sander/10881530

; --- Assignment 3 - Template ---
; Please use this template as a basis for the code to generate the behaviour of your smart vacuum cleaner.
; However, feel free to extend this with any variable or method you think is necessary.


; --- Settable variables ---
; The following settable variables are given as part of the 'Interface' (hence, these variables do not need to be declared in the code):
;
; 1) dirt_pct: this variable represents the percentage of dirty cells in the environment.
; For instance, if dirt_pct = 5, initially 5% of all the patches should contain dirt (and should be cleaned by your smart vacuum cleaner).


; --- Global variables ---
; The following global variables are given.
;
; 1) total_dirty: this variable represents the amount of dirty cells in the environment.
; 2) time: the total simulation time.
; 3) num_of_tiles: total number of tiles in the envoirment
; 4) exit: boolean wihch indicates when the simulation should stop
globals [total_dirty time num_of_tiles exit]


; --- Agents ---
; The following types of agent (called 'breeds' in NetLogo) are given. (Note: in Assignment 3.3, you could implement the garbage can as an agent as well.)
;
; 1) vacuums: vacuum cleaner agents.
; 2) garbage-cans: represents the location where an agent can drop the dirt in the garbage bag
breed [vacuums vacuum]
breed [ garbage-cans garbage-can ]


; --- Local variables ---
; The following local variables are given. (Note: you might need additional local variables (e.g., to keep track of how many pieces of dirt are in the bag in Assignment 3.3). You could represent this as another belief, but it this is inconvenient you may also use another name for it.)
;

; 1) beliefs: the agent's belief base about locations that contain dirt
; 2) desire: the agent's current desire
; 3) intention: the agent's current intention
; 4) performed-cleaning : boolean that is true when the agent performed a cleaning action
; 5) amount_of_dirt: amount of dirt in the garbage bag of the agent
; 6) garbage_bag_size: size of the garbage bag of the vacuum cleaner
; 7) performed-dropping: boolean which is true after an agent emptied its garbage bag
vacuums-own [beliefs desire intention performed-cleaning amount_of_dirt garbage_bag_size performed-dropping]


; --- Setup ---
to setup
  clear-all
  print "         "
  ; setup environment and vacuum cleaner
  setup-patches
  setup-vacuums
  setup-garbage-can
  setup-ticks

  set time 0
  set exit false

  reset-ticks
  reset-timer
end


; --- Main processing cycle ---
to go
  ; This method executes the main processing cycle of an agent.
  ; For Assignment 3, this involves updating desires, beliefs and intentions, and executing actions (and advancing the tick counter).
  update-desires
  update-beliefs
  ; if all the dirt is gone, stop the main loop. This is when the angent has the belief that there is no dirt in the room anymore.
  if exit
    [ stop ]
  ; update new intention based in the current state of the environment
  update-intentions
  execute-actions
  set time timer
  tick
end


; --- Setup patches ---
to setup-patches
  ; In this method you may create the environment (patches), using colors to define dirty and cleaned cells.
  set num_of_tiles ((max-pxcor * 2) + 1) * ((max-pycor * 2) + 1)
  set total_dirty round (dirt_pct * num_of_tiles / 100)
  if num_of_tiles = total_dirty [ error "The dirt percentage is too high. Please lower the percentage!" ]
  ask n-of total_dirty patches [
      set pcolor grey
  ]
end


; --- Setup vacuums ---
to setup-vacuums
  ; In this method you may create the vacuum cleaner agents (in this case, there is only 1 vacuum cleaner agent).
  set-default-shape vacuums "ufo top" ; proper  way to visualise the vacuum cleaner
  ; set the vacuum cleaner on a 'clean' tile
  create-vacuums 1 [
    move-to one-of patches with [ pcolor != grey ]
    facexy xcor ycor + 1
    set performed-cleaning false
    set performed-dropping false
    set color red
    ; setup the beliefs of the agent based on the start state of the environment
    setup-beliefs
    set amount_of_dirt 0
    ; maximum number of dirty tiles an agent can carry in its bag
    set garbage_bag_size 5
 ]
end

; --- Setup the garbage can ---
to setup-garbage-can
  set-default-shape garbage-cans  "garbage-can"
  create-garbage-cans 1 [
  move-to one-of patches with [ pcolor != grey ]
  set color  red
  ]

end

; --- Setup ticks ---
to setup-ticks
  reset-ticks
  ; In this method you may start the tick counter.
end


; --- Update desires ---
to update-desires
  ; You should update your agent's desires here.
  ; At the beginning your agent should have the desire to clean all the dirt.
  ; If it realises that there is no more dirt, its desire should change to something like 'stop and turn off'.

  ; beliefs should be a list of all dirty patches, if list is empty then agent desire to clean the room
  ; is "switch off" because the room is cleaned up.
  ask vacuums [
    ifelse length beliefs >= 1
        ; the desire is clean all the  dirty patches in the environmnet. If this desire is true, there are dirty patches left,
        ; if not then all the dirt is gone and the desire to clean the envoriment is false.
        ; we decided not to make a desire of "empty garbage bag". This desire is part of the the whole desire to clean all the
        ; dirty patches in the environment, emptying the garbage bag is modeled as an intention of an agent
        [
          set desire true
        ]
        [
          set desire false
          set exit true
        ]
  ]
end

; --- Setup desires ---
to setup-beliefs
  ; when the simulation starts the agent will receive full information about the environment, therefor it will know where the dirt is
  ; located in the room.
  ask vacuums [
   set beliefs [self] of patches with [pcolor = gray]
  ]
end

; --- Update desires ---
to update-beliefs
 ; You should update your agent's beliefs here.
 ; At the beginning your agent will receive global information about where all the dirty locations are.
 ; This belief set needs to be updated frequently according to the cleaning actions: if you clean dirt, you do not believe anymore there is a dirt at that location.
 ; In Assignment 3.3, your agent also needs to know where is the garbage can.
 ask vacuums [
   if performed-cleaning
   [
     ; if the agent performed a cleaning action, remove the belief of dirt on that location from the belief list
     ; for this assignment we sort the beliefs on nearest dirty patch
     set beliefs remove-item  0 sort-by [ distance ?1 < distance ?2 ] beliefs
     set performed-cleaning false
   ]
   if length beliefs = 0
   [
     set exit true
   ]
 ]

end


; --- Update intentions ---
to update-intentions
  ; You should update your agent's intentions here.
  ; The agent's intentions should be dependent on its beliefs and desires.
  ask vacuums [
    ; if the garbage bag is full, go to the garbage can, else set intention to a dirty patch or clean a dirty patch if you are there.
    ifelse  amount_of_dirt >= garbage_bag_size
       [
         set intention one-of garbage-cans
       ]
       [

         if intention = 0 and amount_of_dirt < garbage_bag_size
         [
           ; if the agent has no intention, and the bag is not full yet set intention to one of the dirty patches beliefs
           set intention  item 0 sort-by [ distance ?1 < distance ?2 ] beliefs
         ]
         if patch-here = intention and amount_of_dirt != garbage_bag_size
         ; if the vacuum cleaner entered a diry patch
         [
           set intention "clean-dirt"
         ]
      ]
  ]
end


; --- Execute actions ---
to execute-actions
  ; Here you should put the code related to the actions performed by your agent: moving and cleaning (and in Assignment 3.3, throwing away dirt).
  ask vacuums [
    ifelse intention != "clean-dirt" and patch-ahead 1 != "nobody"
      [
        ; this prevents a error when the next patch is outside the environment, if this is true, go to the current intention
        let target patch-ahead 1
        ifelse is-patch? target
         [
           ifelse any? garbage-cans-on patch-ahead 1  and not performed-dropping
           ; drop dirt if the agent not already did this
           [
             ; NOTE: please be aware that our agent never really "stands on the garbage can", just slightly in front
             ; of it. We did this with intention, because "humans" also don't move "on top of" the garbage can
             drop-dirt
           ]
           [
             face intention
             forward 1
             set performed-dropping  false
           ]
         ]
         [
           face intention
           forward 1
           set performed-dropping  false
         ]
      ]
      [
        ; else clean dirt
        clean-dirt
      ]
  ]


end

; --- clean the dirty patch ---
to clean-dirt
  ask vacuums [
    if pcolor = grey and intention = "clean-dirt" [
      set pcolor black
      set intention  0
      set performed-cleaning true
      set total_dirty total_dirty - 1
      set amount_of_dirt amount_of_dirt + 1
      ; print amount_of_dirt
    ]
 ]
end

; --- Empty the bag with dirty tiles ---
to drop-dirt
  ask vacuums [
    if any? garbage-cans-on patch-ahead 1
     [
       set amount_of_dirt 0
       set intention  0
       set performed-dropping true
     ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
782
17
1382
638
12
12
23.6
1
10
1
1
1
0
0
0
1
-12
12
-12
12
1
1
1
ticks
30.0

SLIDER
11
49
777
82
dirt_pct
dirt_pct
0
100
17
1
1
NIL
HORIZONTAL

BUTTON
11
17
395
50
NIL
go
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
394
17
777
50
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
1

MONITOR
12
115
778
160
Number of dirty cells left.
total_dirty
17
1
11

BUTTON
11
82
777
115
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

MONITOR
12
160
778
205
The agent's current desire.
[desire] of vacuum 0
17
1
11

MONITOR
12
205
778
250
The agent's current belief base.
[beliefs] of vacuum 0
1000
1
11

MONITOR
12
295
778
340
Total simulation time.
time
17
1
11

MONITOR
12
250
778
295
The agent's current intention.
[intention] of vacuum 0
17
1
11

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

garbage-can
false
0
Polygon -16777216 false false 60 240 66 257 90 285 134 299 164 299 209 284 234 259 240 240
Rectangle -7500403 true true 60 75 240 240
Polygon -7500403 true true 60 238 66 256 90 283 135 298 165 298 210 283 235 256 240 238
Polygon -7500403 true true 60 75 66 57 90 30 135 15 165 15 210 30 235 57 240 75
Polygon -7500403 true true 60 75 66 93 90 120 135 135 165 135 210 120 235 93 240 75
Polygon -16777216 false false 59 75 66 57 89 30 134 15 164 15 209 30 234 56 239 75 235 91 209 120 164 135 134 135 89 120 64 90
Line -16777216 false 210 120 210 285
Line -16777216 false 90 120 90 285
Line -16777216 false 125 131 125 296
Line -16777216 false 65 93 65 258
Line -16777216 false 175 131 175 296
Line -16777216 false 235 93 235 258
Polygon -16777216 false false 112 52 112 66 127 51 162 64 170 87 185 85 192 71 180 54 155 39 127 36

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

ufo top
false
0
Circle -1 true false 15 15 270
Circle -16777216 false false 15 15 270
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -7500403 true true 60 60 30
Circle -7500403 true true 135 30 30
Circle -7500403 true true 210 60 30
Circle -7500403 true true 240 135 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 135 240 30
Circle -7500403 true true 60 210 30
Circle -7500403 true true 30 135 30
Circle -16777216 false false 30 135 30
Circle -16777216 false false 60 210 30
Circle -16777216 false false 135 240 30
Circle -16777216 false false 210 210 30
Circle -16777216 false false 240 135 30
Circle -16777216 false false 210 60 30
Circle -16777216 false false 135 30 30
Circle -16777216 false false 60 60 30

vacuum-cleaner
true
0
Circle -7500403 true true 69 204 42
Circle -7500403 true true 189 204 42
Polygon -7500403 true true 30 210 270 210 270 195 255 180 240 165 225 150 210 150 195 150 75 150 60 165 45 180 30 195 30 210

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
NetLogo 5.3
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
