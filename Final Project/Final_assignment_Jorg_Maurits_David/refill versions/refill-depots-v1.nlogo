; Final Assignment Multi-Agent systems 2016

; David Zomderdijk/10290745
; Maurits Bleeker/10694439
; Jorg Sander/10881530

breed [builders builder]
breed [depots depot]

;; for development
breed [antennas antenna ]
undirected-link-breed [antenna-links antenna-link]

globals [
         time
         coastline_color                     ; color of coastline
         sea_color                           ; color of the sea
         terrain-color                       ; color of the terrein where agent can walk...sand
         total_num_shore_patches             ; global knowlegde: the total number of shoreline patches to be discovered
         speed_carry_alone                   ; speed of the agent when walking alone
         speed_carry_together                ; speed of the agents when carrying an object togtehter
         speed_w_carry                       ; speed without carrying something
         weight_of_patch
        ]


builders-own [
  belief_costline_patches                ; beliefs about where the coastline is located
  beliefs_depots                         ; beliefs about the location of the depots
  beliefs_empty_depots                   ; beliefs about the empty depots (no resources left)
  belief_all_depots_found                ; belief about the fact whether all depots where discovered
  belief_depot_to_refill                 ; belief about which depot a builder is refilling with resources
  closest-depot                          ; location of the closest depot
  desires                                ; desires of builder
  intentions                             ; intentions of builder
  builder_vision_angle                   ; vision angle of builder
  myradius                               ; the objects that the builder can perceive in its vision radius
  observations                           ; the actual observations the builder just made
  builders_nearby                        ; agentset of builders in my vision cone
  mybodies                               ; NOTE: finally not used, but we leave this in in order to show that we tried this approach
  belief_coast_line_complete             ; belief about the fact that the shore line is complete
  new_shoreline_patches                  ; belief about just discovered shoreline patches
  choosen_shortline                      ; this part of the shortline the agent has choosen to work on
  just_found_shoreline                   ; belief about that fact that I just discovered some shoreline
  belief_carrying_resources              ; belief about the fact whether the builder is carrying a resource (to the shoreline)
  belief_working_alone                   ; Note: finally not used, but we leave this in in order to show that we tried this approach
  found_empty_depot                      ; true if you found a depot that is true
  p_empty_depot                          ; patch of the empty depot agent found
  refilled_depot                         ; just refilled a depot
  do_reconsider                          ; reconsider your intentions
  ;         OUTGOING MESSAGES
  msg_out_b_depots                       ; message wrt beliefs about the depots
  msg_out_b_depots_empty                 ; message wrt beliefs about empty depots
  msg_out_b_selected_coastline_part      ; message wrt the shoreline piece/location the builder just selected to build
  msg_out_b_shoreline                    ; message wrt beliefs about the shoreline location
  msg_out_b_depots_refilled              ; message wrt the depot the builder just refilled
  ;         INCOMING MESSAGES
  msg_in_b_depots                        ; message wrt beliefs about depots (incoming)
  msg_in_b_depots_empty                  ; message wrt beliefs about empty depots
  msg_in_b_shoreline                     ; message wrt beliefs about the shoreline location
  msg_in_b_selected_coastline_part       ; message wrt the shoreline piece/location other builders have discovered
  msg_in_b_depots_refilled               ; message wrt the depot other builders just refilled

]

depots-own [ resources ]


to setup
  set time 0
  clear-all
  setup-coastline
  setup-depots
  setup-builders
  reset-ticks
  reset-timer
end

; initialize the builders
to setup-builders

  ; set globals
  set speed_carry_alone 0.2
  set speed_carry_together 0.7
  set speed_w_carry 1

  create-builders  amount-of-workers [
    set belief_coast_line_complete false
    set belief_all_depots_found false
    set size 4
    set choosen_shortline []
    set beliefs_depots []
    set belief_costline_patches []
    set builder_vision_angle vision-radius
    set color blue
    set desires ["find depots and shoreline"]
    set intentions ["explore world"]
    set msg_in_b_depots []
    set msg_in_b_selected_coastline_part []
    set msg_in_b_shoreline []
    set msg_in_b_depots_empty []
    set msg_in_b_depots_refilled []
    set just_found_shoreline false
    set belief_carrying_resources 0
    set belief_working_alone true
    set found_empty_depot false
    set do_reconsider false
    set p_empty_depot nobody
    set beliefs_empty_depots []
    set refilled_depot false

    move-to one-of patches with [pcolor != coastline_color
      and pxcor < floor (max-pxcor / 2) and not any? turtles-here ]
    set heading random 360
    set myradius patches in-radius vision-radius
    if visualize_vision [ draw-bd-antennas self ]
  ]

end

; initialize the depots
to setup-depots
  create-depots amount-of-depots [
    set shape "factory"
    set color red
    set size 7

    set resources resources-per-depot
    move-to one-of patches with [pcolor != coastline_color
      and ( pxcor <  floor (- max-pxcor / 2) and ( pxcor < (max-pxcor - 10) or pxcor > (min-pxcor + 10) )
      and not any? depots-here
      and ( pycor < (max-pycor - 10) or pycor > (min-pycor + 10) ) ) ]
    set heading 0
    set plabel resources
  ]
end

;; set up the basic environment with the coastline
to setup-coastline

  set terrain-color 44
  set coastline_color 96
  set sea_color 92
  set weight_of_patch 10

  ;; first use a turtle to draw the surface of the coastline
  create-turtles 1 [
    set color coastline_color
    setxy floor (max-pxcor * 0.75) min-pycor
    set heading 0
    repeat world-height [
      set pcolor color
      fd 1

      ;; jagged so vary xcor by the coastline-bumpiness
      if color != black [
        ;; random-poisson gives small variations, sometimes
        ;; larger ones
        let x ( xcor + one-of [1 -1] * random-poisson ( coastline-bumpiness ) )
        ;; prevent the drawing turtle from wrapping horizontally
        ;; while contouring the coastline
        if patch-at (x - xcor) 0 != nobody
          [ set xcor x ]
      ]
    ]
    die

  ]

  ;; then use more turtles to make solid blue below the coast line
  ask patches with [pcolor != black] [
    sprout 1 [
      set heading 90
      ;; if the drawing turtle is already at the bottom it should not continue
      if not can-move? 1 [ die ]
      fd 1
      set pcolor sea_color
      fd 1
      while [ can-move? 1 ]
      [
        set pcolor sea_color
        fd 1
      ]
      set pcolor sea_color
      die
    ]
  ]
  ask patches with [pcolor = black] [ set pcolor terrain-color ]

  ; set the global number of patches once. global knowlegde give to agents in order to determine
  ; when the exploration of the shoreline is complete
  set total_num_shore_patches (max-pycor * 2) + 1

end

to go
  ; we deliberately implemented the following BDI model
  ; (1) first observ
  ; (2) based on observations (and observations of others send/receive messages) update your beliefs
  ; (3) update your desires based on the current intentions and the new beliefs
  ; (4) update your intentions based on the new desires
  ; (5) interact with your environment...execute actions
  do-perceive
  update-beliefs
  update-desires
  update-intentions
  ; Note, if all builders want to drink beer then stop
  if all? builders [ first desires = "have a beer" ]  [ stop ]
  if visualize_vision [ ask builders [ draw-bd-antennas self ] ]
  execute-actions
  tick
  set time timer
end

; observe the environment
to do-perceive
  ask builders [
   ; just get all the patches that I can perceive in the current position
   set myradius patches in-radius vision-radius
   set observations myradius
   set builders_nearby builders in-radius vision-radius
  ]
end

; update beliefs of builders
to update-beliefs
  ; we deliberately combined the update of beliefs with the sending and receiving of messages because
  ; we believe that is a logical thing to do in the BDI model, first "perceive" (on every iteration)
  ; and then update your own beliefs, based on your own observations and the ones from your fellow builders
  ; currently we just accept all beliefs of the other builders unfiltered, we only skip the beliefs that
  ; we already have ourselves

  ask builders [
    ; update beliefs based on observations
    if not belief_all_depots_found [
      set beliefs_depots remove-duplicates sentence beliefs_depots [ self ] of observations with [ any? depots-here ]
    ]

    ; remove empty depot location from beliefs over depots
    if found_empty_depot [

      set beliefs_depots remove p_empty_depot beliefs_depots
      if not member? p_empty_depot beliefs_empty_depots [
        set beliefs_empty_depots fput p_empty_depot beliefs_empty_depots
      ]
      set found_empty_depot false
    ]


    if refilled_depot [
        ; update agent beliefs because depot is REFILLED
        ; also make sure other agents are informed
        set beliefs_depots remove-duplicates sentence beliefs_depots [ patch-here ] of belief_depot_to_refill
        set beliefs_empty_depots remove [ patch-here ] of belief_depot_to_refill beliefs_empty_depots

    ]

    set new_shoreline_patches [] ; first empty the previous list with shortline patches
    set new_shoreline_patches [ self ] of observations with [ pcolor = coastline_color ]
    ; determine if we just observed a patch at the shoreline, we'll use that information in order to determine
    ; where to "go next"
    ifelse length new_shoreline_patches > 0 [ set just_found_shoreline true ] [ set just_found_shoreline false ]
    if not belief_coast_line_complete [ ; only update beliefs about the coastline is belief about is not complete
       set belief_costline_patches remove-duplicates sentence belief_costline_patches new_shoreline_patches
    ]
    ; send your observations to the other agents
    send-messages self

  ]
  ; read messages in order to "synchronize" own beliefs with others
  read-messages


  ask builders [ ; update beleifs if we found all the depots and coastline patches
    if length belief_costline_patches >= total_num_shore_patches
    [
      set belief_coast_line_complete true
    ]
     if length beliefs_depots = amount-of-depots [
       set belief_all_depots_found true
    ]
]
end

; update builders desires
to update-desires
  ask builders [
    ; we initialize every builder with the desire to explore the world
    ; if all goals are fulfilled for this desire then change the desire to build the embankment
    if belief_coast_line_complete and belief_all_depots_found
       and item 0 intentions = "explore world" [
      set desires []
      set desires fput "build embankment" desires
    ]
    ; finally, if the shoreline is complete and the agent just delivered the last piece of
    ; construction material, than change your desire...which we'll use as termination criteria
    if belief_coast_line_complete and belief_all_depots_found
      and total_num_shore_patches <= 0 [
        set desires []
        set desires fput "have a beer" desires
    ]
  ]
end

; update intentions of the builder
to update-intentions
  ask builders [
    if item 0 desires = "find depots and shoreline" [
      ; so we know we haven't yet found all depots and the complete shoreline
      ifelse just_found_shoreline and not belief_coast_line_complete [
        ; I just found a shoreline patch but am I already at the shoreline?
        ; the first simple goal is then to go to shoreline and move along shoreline
        ifelse atShoreline self [
          ; agent is already at the shoreline, so move along the shoreline
          set intentions remove item 0 intentions intentions
          set intentions lput "move along shoreline" intentions
          set just_found_shoreline false
       ]
       [
         ; agent is not yet at the shoreline, so first move to the shoreline
         set intentions remove item 0 intentions intentions
         set intentions lput "move to shoreline" intentions
       ]
      ] ; end if just_found_shoreline
      [
        ; else if just_found_shoreline
        ; if at shoreline and we haven't discoverd it fully yet, then keep on moving along shoreline
        ifelse not belief_coast_line_complete and atShoreline self [
          set intentions remove item 0 intentions intentions
          set intentions lput "move along shoreline" intentions
        ]
        [
         ; if you're not at the coastline yet but all depots have been found but not the complete shoreline
         ; AND we already found at least a piece of shoreline then move to shoreline
         ifelse not belief_coast_line_complete and belief_all_depots_found and length belief_costline_patches > 0 [
            ; we already checked whether we're at the shoreline, not the case if we end up here
            set intentions remove item 0 intentions intentions
            set intentions lput "move to shoreline" intentions
         ]
         [
           ; ok, I am not at the shoreline and we haven't found all depots yet or we just haven't even found
           ; the first patch at the shoreline, so just explore randomly the environment
           set intentions remove item 0 intentions intentions
           set intentions lput "explore world" intentions
         ]
        ]
      ]  ; end ifelse just_found_shoreline
    ] ; end-if desires = "find depots and shoreline"

  ;;;;;;;;;;;;;;;;;;;;;;;;;; ********************   BUILD EMBANKMENT ************************* ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; deduce intentions when desire is to build the embankment...the 2nd phase
  if item 0 desires = "build embankment" [
    ; NOTE, the agent needs to reconsider its intentions when e.g. the beliefs about the depots has shrinked to "zero"
    ;       and we're not anymore exploring the world.
    if-else do_reconsider [

       if item 0 intentions = "find closest depot" [
         ; we end up here, if the depot we wanted to go to has no resources anymore, find a new depot
         if length beliefs_depots = 0 [
           ; so there is no depot left with resources, set intentions to "something" else
           ; NOTE, we're not deleting the last INTENTION, but put a new intention in front of the list/stack
           ; which means, we can re-activate the previous intention after we achieved this intention
           set intentions fput "refill depot" intentions
           ; we need to know which depot needs to be refilled. so we update the belief here.
           ; because agent wanted to go to "closest-depot" we will set the belief about which depot to refill
           ; to that patch, or find the closest depot
           ifelse closest-depot != nobody [
             let depo one-of depots-on closest-depot
             set belief_depot_to_refill depo
           ]
           [
             ; this is problematic, beliefs about depots are empty, and agents does not know where to go
             ; in this case we send him to one of the empty depots
             set beliefs_depots fput one-of beliefs_empty_depots  beliefs_depots
           ]
         ]

       ]
       if item 0 intentions = "pick up resources" [

           ; make sure that there is still another depot with resources
           ifelse length beliefs_depots > 0 [
             set intentions remove item 0 intentions intentions
             set intentions fput "find closest depot" intentions
           ]
           [  ; ok, no other depot with resources left, change intention
              ; and again note, we're stacking the intentions, the "old" one is not lost
              set intentions fput "refill depot" intentions
              ; same story as above, agent needs to know which depot to refill, therefore we update the belief
              ; about which depot to refill here
              ifelse closest-depot != nobody [
                let depo one-of depots-on closest-depot
                set belief_depot_to_refill depo
              ]
              [
                set closest-depot item 0 sort-by [ distance ?1 < distance ?2 ] beliefs_depots
                let depo one-of depots-on closest-depot
                set belief_depot_to_refill depo
              ]
           ]
       ]

       if first intentions = "go to building spot" [
         ; we end up here if the builder is on his way to the shoreline but in the mean time all depots are empty
         ; we are going to put ONE belief (random) back into his belief list about the depots because we want the
         ; builder to return to that depot, discover that the depot is empty and refill that depot
         if length beliefs_depots = 0 [
            set beliefs_depots fput one-of beliefs_empty_depots  beliefs_depots
         ]

       ]
       set do_reconsider false
       ; end do reconsider

    ] ; end do reconsider

    [
      ; if the agent is not carrying any resources, go to a depot to get resources
      if-else belief_carrying_resources = 0
      [
        ; here the agent does not have any resources, it needs to get one at the depot
        ;let amount_of_resources [resources] of other depots-here
        if-else any? other depots-here and first intentions !=  "refill depot" [
          ; when arrived at the depot, pick up resources and only if there are resources left
          set intentions remove item 0 intentions intentions
          set intentions lput "pick up resources" intentions
        ]
        [
          ; we are not carrying anything and we're not at a depot
          ; need to decide what to do.
          ; (1) search for closest depot to pick up construction material or
          ; (2) find a budy that we can help carrying the material
          if-else first intentions = "refill depot" [
            ; check whether the depot the agent needs to refill is filled up
            ; NOTE, strange way of selecting the depot

            if-else [ resources >= resources-per-depot ] of belief_depot_to_refill  [
               ; update agent intention because depot is REFILLED
               ; we just have to remove the first intention, the "former" intention is still in the list

               set intentions remove item 0 intentions intentions
               set refilled_depot false
               set belief_depot_to_refill nobody

            ]
            [
              ; keep intention, still need to refill the depot
              ask belief_depot_to_refill [ set resources resources + refill-per-tick]

              if [ resources >= resources-per-depot ] of belief_depot_to_refill [
                 set refilled_depot true
              ]
            ]

          ]
          [
            ;find closest depot if you do not have resources
            set intentions remove item 0 intentions intentions
            set intentions lput "find closest depot" intentions
          ]
        ]
      ]
      [
        ; you have resources at the moment
        if-else patch-ahead 1 != nobody and [pcolor = coastline_color] of patch-ahead 1
        [
          ;find you are arrived at the coastline where you want to build
          set intentions remove item 0 intentions intentions
          set intentions lput "build embankment" intentions

        ]
        [
          ; you have resources but you are not arrived yet
          if-else length choosen_shortline > 0
          [
            ; if you have chooses a building spot go there
            ; IF-ELSE to prevent the issue we had previously that a builder "get's stuck at the shoreline"
            ; but each time check whether the building spot is not yet filled by somebody else in the mean time
            if-else [ pcolor != coastline_color ] of first choosen_shortline [
              ; select a building spot
              set intentions remove item 0 intentions intentions
              set intentions lput "find building spot" intentions
            ]
            [
              set intentions remove item 0 intentions intentions
              set intentions lput "go to building spot" intentions
            ]
          ]
          [
            ; select a building spot
            set intentions remove item 0 intentions intentions
            set intentions lput "find building spot" intentions
          ]
        ]
      ] ; end of else: you have resources at the moment
    ] ; end else: do reconsider
  ] ; end if: desires = "build embankment"

 ]  ; end ask builders
end

to execute-actions
  ask builders [
    if-else item 0 desires != "build embankment" [
      if item 0 intentions = "explore world" [ move-random self ]
      if item 0 intentions = "move to shoreline" [ move-to-shoreline self ]
      if item 0 intentions = "move along shoreline" [ move-along-shoreline-v1 self ]
    ]
    [
      if item 0 intentions = "find closest depot" [
        ; IT IS POSSIBLE THAT WE END UP HERE BUT THE BELIEFS ABOUT THE DEPOTS ARE EMPTY
        ; IN THAT CASE SET RECONSIDER TO TRUE
        if-else length beliefs_depots > 0 [
          set closest-depot item 0 sort-by [ distance ?1 < distance ?2 ] beliefs_depots
          face closest-depot
          fd 1
        ]
        [
          set do_reconsider true
        ]
      ]
      if item 0 intentions = "pick up resources" [
        ; check the amount of resources for this depot
        ; als er niet genoeg resources zijn zeg found_empty_depot true
        let resources_left [resources] of other depots-here
        if-else item 0  resources_left >= weight_of_patch [
          ; if there are enought resources left
          set belief_carrying_resources weight_of_patch
          ask other depots-here [
            set resources round (resources - weight_of_patch)
            set plabel resources
          ]
        ]
        [
         ; depot is nearly empty, remember the patch of the depot, because we'll delete it from the beliefs over depots
         set found_empty_depot true
         set p_empty_depot patch-here
         set do_reconsider true
        ]
      ]
      if item 0 intentions = "find building spot" [
        if length belief_costline_patches > 0 [
          let closest-coastline item 0 sort-by [ distance ?1 < distance ?2 ] belief_costline_patches
          set choosen_shortline []
          set choosen_shortline lput closest-coastline choosen_shortline
          face closest-coastline

          ;  send messages to other agents to that they selected this patch so that they don't select that one anymore
          ifelse belief_working_alone [
            fd speed_carry_alone
          ]
          [
            fd speed_carry_together
          ]
        ]

      ]
      if item 0 intentions = "go to building spot" [
        face item 0 choosen_shortline
        ifelse belief_working_alone [
          fd speed_carry_alone
        ]
        [
          fd speed_carry_together
        ]
      ]
      if item 0 intentions = "build embankment" [
         set belief_carrying_resources 0
         ask patch-ahead 1 [
             set pcolor red
         ]
         set total_num_shore_patches total_num_shore_patches - 1
         set choosen_shortline []
      ]

      if item 0 intentions =  "refill depot" [
        ; NEEDS IMPLEMENTATION, WHAT ARE WE GOING TO DO IF THE DEPOTS ARE ALL EMPTY AND BUILDER IS AT DEPOT?
        ; Two possibilities
        ; (1) OR AGENT IS AT THE DEPOT
        ; (2) OR AGENT IS ON HIS WAY TO DEPOT

      ]


    ] ; end ifelse "build embankment"

]  ; end ask builders

end ; execute-actions

; try to move to shoreline, choose the costline patch that is closest for you
; could be improved because could be that suddently all builders head to the same location...for later if we have time
to move-to-shoreline [ bd ]
  face item 0 sort-by [ distance-nowrap ?1 < distance-nowrap ?2 ] belief_costline_patches
  fd 1
end

; simpel first version
; ASSUMPTION: the shoreline is a straight line, let us begin with that, we will improve that
to move-along-shoreline-v1 [ bd ]
  ; we know we're at the shoreline, otherwise we don't end up here. This procedure can be optimized, no doubt
  ; we start in the simplest version
  ; because we know that the shoreline is a vertical line, we can hold our x-direction
  ; so first face north or south if you have not done so
  ifelse heading != 0 and heading != 180 [
    ; randomly choose one direction
    set heading one-of [ 0 180 ]

  ]
  [
     ; just move north or south if possible, otherwise turn 180 degrees
     ifelse not can-move? 1 [
       ; turn 180 degrees
       set heading (180 + heading)
       fd 1
     ]
     [
       fd 1
     ]
  ]


end

;this function makes the agent move random, however, the agent will only change direction if it cannot go any further.
to move-random [ builder ]
  ask builder [

    let target_patch patch-ahead 1
    let obstacle true

    while[obstacle] [
      set target_patch patch-ahead 1
      if target_patch != nobody
          [face target_patch ]

      ifelse target_patch != nobody and not any? turtles-on target_patch and [pcolor] of target_patch != coastline_color
          [
          set obstacle false
          move-to target_patch

          ]

        [ ;here we determine which direction the agent needs to move
          let random_dir random 1
          ;with this variable we can determine wether an agent heads left or right x degrees.
          let random_dir2 1
          if random_dir = 1 [ set random_dir2 -1]

          ;if on bumps on the northern side of the grid one the basis of the direction move x degrees to left or right
          ifelse ycor + 1 > max-pycor
            [ifelse  heading < 91
              [ set heading heading + 90 + random 50 ]
              [ set heading heading  - 90 - random 50]
            ]
          ;if on bumps on the southern side of the grid one the basis of the direction move x degrees to left or right
          [ ifelse ycor - 1 < min-pycor
            [ifelse heading > 360
              [ set heading heading + 90 + random 50]
              [ set heading heading - 90 - random 50]
            ]

          [ifelse xcor - 1 < min-pxcor
            [ ifelse heading > 270
              [ set heading heading + 90 + random 50 ]
              [ set heading heading - 90 - random 50]
            ]
            [set heading heading + random_dir2 * 90 + random_dir2 * random 50 ]
            ]
          ]
        ]
    ] ; end while obstacle

    if visualize_vision [ ask [ antennas ] of builder [ die ] ]
  ]
end

; --- Send messages ---
to send-messages [ bd ]

;here we set the outgoing messages for every builder

  ;(re)initialize outgoing messages to what you just observed
  set msg_out_b_depots []
  set msg_out_b_shoreline []
  set msg_out_b_selected_coastline_part []
  set msg_out_b_depots [ self ] of observations with [ any? depots-here ]
  set msg_out_b_shoreline [ self ] of observations with [ pcolor = coastline_color ]
  set msg_out_b_selected_coastline_part choosen_shortline
  set msg_out_b_depots_empty []
  set msg_out_b_depots_refilled []

  if refilled_depot [
     set msg_out_b_depots_refilled fput [ patch-here ] of belief_depot_to_refill msg_out_b_depots_refilled
  ]

  ;set msg_out_b_selected_coast_line_part [ self ]
  ; combine your observations with the incoming message queue of OTHER builders
  if length msg_out_b_depots > 0 [
    ask other builders [ set msg_in_b_depots remove-duplicates sentence msg_in_b_depots [msg_out_b_depots] of bd ]
  ]

  if-else not belief_coast_line_complete [
    if length msg_out_b_shoreline > 0 [
      ask other builders [ set msg_in_b_shoreline remove-duplicates sentence msg_in_b_shoreline [ msg_out_b_shoreline ] of bd ]
    ]
  ]
  [
    ask other builders [ set msg_in_b_shoreline []]
  ]

  if  length msg_out_b_selected_coastline_part > 0 [
    ask builders [ set msg_in_b_selected_coastline_part remove-duplicates sentence msg_in_b_selected_coastline_part [ msg_out_b_selected_coastline_part ] of bd ]
  ]

  ; if I found an empty depot, send messages to others
  if p_empty_depot != nobody [
    set msg_out_b_depots_empty p_empty_depot
    ask other builders [ set msg_in_b_depots_empty remove-duplicates sentence msg_in_b_depots_empty [ msg_out_b_depots_empty ] of bd ]
    set p_empty_depot nobody
  ]

  if length msg_out_b_depots_refilled > 0 [
     ask other builders [ set msg_in_b_depots_refilled remove-duplicates sentence msg_in_b_depots_refilled [ msg_out_b_depots_refilled ] of bd ]
  ]

end

; --- Send messages ---
to read-messages
;combine builders belief with beliefs send by other builders
ask builders [
  if length msg_in_b_depots > 0  and not belief_all_depots_found[
    set beliefs_depots remove-duplicates sentence beliefs_depots msg_in_b_depots
  ]

  if length msg_in_b_shoreline > 0 [
    set belief_costline_patches remove-duplicates sentence belief_costline_patches msg_in_b_shoreline
  ]
  ; recieved message from other agent about building at coastline
  if length msg_in_b_selected_coastline_part > 0 [
    ; for all incomming messeges remove them from beliefs
    foreach msg_in_b_selected_coastline_part [

    let coordinates ?
    let index 0

    foreach belief_costline_patches [
       let temp_element ?
       if  temp_element = coordinates [
         set belief_costline_patches remove-item index belief_costline_patches
       ]
       set index index + 1
    ]
  ]
 ]  ; end length msg_in_b_selected_coastline_part > 0

 ; any message that a depot has no resources anymore?
 if length msg_in_b_depots_empty > 0 [
    foreach msg_in_b_depots_empty [
       if member? ? beliefs_depots [
         set beliefs_depots remove ? beliefs_depots
         if not member? ? beliefs_empty_depots [
           set beliefs_empty_depots fput ? beliefs_empty_depots
         ]
         ; if my current intention is to pick-up a resource and I want to go to the depot that has no resources anymore
         ; than I need to reconsider my intentions
         if closest-depot = ? and item 0 intentions = "find closest depot" [
           set do_reconsider true

         ]
       ]
    ]
    ; in any case, if all my beliefs about depots are GONE (because they have no resources anymore, THEN RECONSIDER your intentions
    if length beliefs_depots = 0 [
      set do_reconsider true
    ]
    set msg_in_b_depots_empty []
 ]

 ; any depots refilled? update beliefs
 if length msg_in_b_depots_refilled > 0 [
    foreach beliefs_empty_depots [
      ; remove refilled depot from list of empty depots
      if member? ? beliefs_empty_depots [
        set beliefs_empty_depots remove ? beliefs_empty_depots
      ]
      ; add refilled depot to list of beliefs about depots
      if not member? ? beliefs_depots [
        set beliefs_depots fput ? beliefs_depots
      ]
    ]
    set msg_in_b_depots_refilled []
 ]

]
end

; determine whether I am at the shoreline, returning true/false
to-report atShoreline [ bd ]
  ifelse any? neighbors4 with [ pcolor = coastline_color ]
  [ report true ]
  [ report false ]

end


; visualize vision radius
to draw-bd-antennas [ bd ]

  ; update my radius (needed for the antennas)

  ask myradius [
    sprout-antennas 1 [
    set shape "dot"
    set size 0.3
    set color [color] of bd
    create-antenna-link-with bd
    set color [color] of bd
    ]
  ]
  display
end

to-report find-budies [ bd ]
  let potential_budies builders_nearby with [ belief_working_alone = true and belief_carrying_resources > 0 and length choosen_shortline > 0 ]
  let final_budy_list []
  foreach [self] of potential_budies [
     let patch_budy [ patch-here ] of ?
     ; is distance form me to budy greater than certain threshold, otherwise I am not allowed to coorporate with hem/her
     if  distance-nowrap patch_budy > coorperation_threshold [
       set final_budy_list fput ? final_budy_list
     ]
   ] ; end foreach
   report sort-by [ distance-nowrap ?1 < distance-nowrap ?2 ] final_budy_list

end

to-report work-with-budy? [ bd budy ]

  print budy
  ; get patch where budy is situated
  let patch_budy [patch-here] of budy
  let shore_line_patch [ item 0 choosen_shortline ] of budy
  ; compute distance between "me" and budy
  let dist_to_budy distance-nowrap patch_budy
  ; compute distance between budy and shoreline
  let dist_budy_to_shoreline [ distance-nowrap patch_budy ] of shore_line_patch
  ; total distance before I would "get my next reward" if I would help budy
  ; NOTE: because the distance to the shoreline will be travelled in "speed" speed_carry_together,
  ; we use the invers of that factor (because it's < 1) to calc the total distance from budy to shoreline
  let total_dist_with_budy ( dist_to_budy + ( ( 1 / speed_carry_together) * dist_budy_to_shoreline ) )

  ; now calculate the distance if I would pick-up a patch at the nearest depot and then go to the shoreline
  ; the last part is an approximation
  let closest-coastline item 0 sort-by [ distance-nowrap ?1 < distance-nowrap ?2 ] belief_costline_patches
  let new_closest-depot item 0 sort-by [ distance-nowrap ?1 < distance-nowrap ?2 ] beliefs_depots
  ; ok, my distance to closest depot
  let dist_to_depot distance-nowrap new_closest-depot
  let dist_depot_to_shoreline [ distance-nowrap closest-depot ] of closest-coastline
  let total_dist_alone ( dist_to_depot + ( ( 1 / speed_carry_alone) * dist_depot_to_shoreline) )

  ifelse total_dist_alone > total_dist_with_budy [
    ; YES, work together with budy
      print (word total_dist_alone " > "  total_dist_with_budy)
      report true
  ]
  [
    ; NO, just work alone, you're better off
    report false
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
391
12
1188
570
60
40
6.51
1
10
1
1
1
0
0
0
1
-60
60
-40
40
0
0
1
ticks
60.0

SLIDER
13
62
185
95
coastline-bumpiness
coastline-bumpiness
0
10
0
1
1
NIL
HORIZONTAL

BUTTON
14
20
77
53
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

SLIDER
11
127
183
160
amount-of-depots
amount-of-depots
0
15
2
1
1
NIL
HORIZONTAL

SLIDER
12
95
183
128
amount-of-workers
amount-of-workers
0
30
5
1
1
NIL
HORIZONTAL

SLIDER
11
160
183
193
vision-radius
vision-radius
0
360
19
1
1
NIL
HORIZONTAL

SLIDER
11
197
183
230
resources-per-depot
resources-per-depot
0
100
50
1
1
NIL
HORIZONTAL

BUTTON
186
22
249
55
go
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
95
21
158
54
go
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

MONITOR
9
249
385
294
Beliefs of depots builder 0
[beliefs_depots] of builder min [ who ] of builders
17
1
11

MONITOR
7
340
151
385
Intentions of builder 1
[intentions] of builder min [ who ] of builders
17
1
11

MONITOR
7
296
384
341
Beliefs of shoreline builder
[belief_costline_patches] of builder min [ who ] of builders
17
1
11

MONITOR
5
451
382
496
Beliefs wrt depots builder2
[beliefs_depots] of builder min [ who + 1 ] of builders
17
1
11

MONITOR
5
497
381
542
Beliefs wrt shoreline builder 2
[belief_costline_patches] of builder min [ who + 1 ] of builders
17
1
11

MONITOR
5
541
149
586
Intention of builder 2
[intentions] of builder min [ who + 1 ] of builders
17
1
11

MONITOR
151
341
384
386
Message out wrt depots builder 1
[msg_out_b_depots] of builder min [ who ] of builders
17
1
11

SLIDER
186
61
365
94
coorperation_threshold
coorperation_threshold
0
100
20
1
1
NIL
HORIZONTAL

MONITOR
8
388
207
433
Belief wrt depot to be refilled builder 1
[ belief_depot_to_refill ] of builder min [ who ] of builders
17
1
11

MONITOR
207
389
384
434
Beliefs wrt empty depots builder 1
[beliefs_empty_depots ] of builder min [ who + 1 ] of builders
17
1
11

MONITOR
149
541
381
586
Message out wrt depots builder 2
[msg_out_b_depots] of builder min [ who + 1] of builders
17
1
11

MONITOR
5
585
197
630
Belief wrt depot to be refilled builder 2
[ belief_depot_to_refill ] of builder min [ who + 1 ] of builders
17
1
11

MONITOR
197
586
382
631
Beliefs wrt empty depots builder 2
[beliefs_empty_depots ] of builder min [ who + 1 ] of builders
17
1
11

SWITCH
187
97
365
130
visualize_vision
visualize_vision
1
1
-1000

MONITOR
187
132
325
177
NIL
time
17
1
11

PLOT
1195
11
1395
161
Resources to build shoreline
Time
Resources
0.0
100.0
0.0
250.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot sum [resources] of depots"

INPUTBOX
188
180
328
240
refill-per-tick
0.2
1
0
Number

PLOT
1198
178
1398
328
Remaining shoreline to be build
Time
Length remaining
0.0
1000.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot total_num_shore_patches"

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

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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
