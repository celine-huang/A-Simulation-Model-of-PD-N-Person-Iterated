globals [
  ;;number of turtles with each strategy
  num-cooperator
  num-random
  num-defector
  num-unforgiving
  num-tit-for-tat
  num-discriminating-altruist
  num-win-stay-lose-shift
  num-true-believer
  num-opportunist
  num-no-interaction

  ;;number of interactions by each strategy
  num-cooperator-games
  num-random-games
  num-defector-games
  num-unforgiving-games
  num-tit-for-tat-games
  num-discriminating-altruist-games
  num-win-stay-lose-shift-games
  num-true-believer-games
  num-opportunist-games
  num-no-interaction-games

  ;;total population of all turtles playing each strategy
  cooperator-population
  random-population
  defector-population
  unforgiving-population
  tit-for-tat-population
  discriminating-altruist-population
  win-stay-lose-shift-population
  true-believer-population
  opportunist-population
  no-interaction-population
]

turtles-own [
  strategy
  totalpayoff
  payoff
  hatch-chance
  die-chance
  partnered?        ;;am I partnered?
  partner           ;;WHO of my partner (nobody if not partnered)
  partner-strategy
  partner-action    ;;action of the partner
  partner-actioned  ;;action the partner has done
  partner-history   ;;a list containing information about past interactions with other turtles (indexed by WHO values)
]

;;;;;;;;;;;;;;;;;;;;;;
;;;Setup Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  store-initial-turtle-counts ;;record the number of turtles created for each strategy
  setup-turtles ;;setup the turtles and distribute them randomly
  reset-ticks
end

;;record the number of turtles created for each strategy
;;The number of turtles of each strategy is used when calculating average payoffs.
;;Slider values might change over time, so we need to record their settings.
;;Counting the turtles would also work, but slows the model.
to store-initial-turtle-counts
  set num-cooperator n-cooperator
  set num-random n-random
  set num-defector n-defector
  set num-unforgiving n-unforgiving
  set num-tit-for-tat n-tit-for-tat
  set num-discriminating-altruist n-discriminating-altruist
  set num-win-stay-lose-shift n-win-stay-lose-shift
  set num-true-believer n-true-believer
  set num-opportunist n-opportunist
  set num-no-interaction n-no-interaction
end

;;setup the turtles and distribute them randomly
to setup-turtles
  make-turtles ;;create the appropriate number of turtles playing each strategy
  let num-turtles count turtles
  ask turtles [
    setup-common-variables ;;sets the variables that all turtles share
    setup-history-lists num-turtles ;;initialize PARTNER-HISTORY list in all turtles
    setxy random-xcor random-ycor
  ]
end

;;create the appropriate number of turtles playing each strategy
to make-turtles
  create-turtles num-cooperator [ set strategy "cooperator" set color blue set shape "person" ]
  create-turtles num-random [ set strategy "random" set color gray set shape "person" ]
  create-turtles num-defector [ set strategy "defector" set color red set shape "person" ]
  create-turtles num-unforgiving [ set strategy "unforgiving" set color turquoise set shape "person" ]
  create-turtles num-tit-for-tat [ set strategy "tit-for-tat" set color lime set shape "person" ]
  create-turtles num-discriminating-altruist [ set strategy "discriminating-altruist" set color magenta set shape "person" ]
  create-turtles num-win-stay-lose-shift [ set strategy "win-stay-lose-shift" set color pink set shape "person" ]
  create-turtles num-true-believer [ set strategy "true-believer" set color brown set shape "person" ]
  create-turtles num-opportunist [ set strategy "opportunist" set color yellow set shape "person" ]
  create-turtles num-no-interaction [ set strategy "no-interaction" set color cyan set shape "person" ]
end

;;set the variables that all turtles share
to setup-common-variables
    set hidden? false
    set partnered? false
    set partner nobody
    set totalpayoff 0
    set payoff 0
    set hatch-chance 0
    set die-chance 0
end

;;initialize PARTNER-HISTORY list in all turtles
to setup-history-lists [ num-turtles ]
  let default-history [] ;;initialize the DEFAULT-HISTORY variable to be a list
  ;;create a list with NUM-TURTLE elements for storing partner histories
  repeat num-turtles [ set default-history (lput "false" default-history) ]
  ;;give each turtle a copy of this list for tracking partner histories
  set partner-history default-history
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;;Runtime Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  clear-last-round
  do-evolution
  ask turtles with [ hidden? = false ] [ partner-up ]  ;;have turtles try to find a partner
  let partnered-turtles turtles with [ partnered? ]
  ask partnered-turtles [ select-action ]           ;;all partnered turtles select action
  ask partnered-turtles [ update-history ]
  ask partnered-turtles [ get-payoff ]              ;;calculate the payoff for this round
  do-population
  tick
end

to clear-last-round
  let partnered-turtles turtles with [ partnered? ]
  ask partnered-turtles [ release-partners ]
end

;;release partner and turn around to leave
to release-partners
  set partnered? false
  set partner nobody
  rt 180 fd 2
  set label ""
end

to do-evolution
  let original-turtles count turtles
  ask turtles [ do-hatch original-turtles ]
  let new-turtles count turtles
  ask turtles [ repeat (new-turtles - original-turtles) [ set partner-history (lput "false" partner-history) ] ]
  ask turtles [ do-die ]
end

to do-hatch [ num-turtles ]
  let parent-strategy strategy
  let parent-color color
  if hatch-chance = 100 [
    hatch 1 [
      set strategy parent-strategy
      set color parent-color
      setup-common-variables ;;sets the variables that all turtles share
      setup-history-lists num-turtles ;;initialize PARTNER-HISTORY list in all turtles
      setxy random-xcor random-ycor  ;;rt (random-float 90 - random-float 90) fd 2  ;;the child turns and moves away
    ] ;; this turtle creates one new turtle, and initializes it
  ]
  set hatch-chance 0
end

to do-die
  if random 100 < die-chance [ set hidden? true ]
  set die-chance 0
end

;;have turtles try to find a partner
;;Since other turtles that have already executed partner-up may have
;;caused the turtle executing partner-up to be partnered,
;;a check is needed to make sure the calling turtle isn't partnered.

to partner-up ;;turtle procedure
  if (not partnered?) [              ;;make sure still not partnered
    rt (random-float 90 - random-float 90) fd 1     ;;move around randomly
    set partner one-of (turtles-at -1 0) with [ not partnered? ]
    if partner != nobody [              ;;if successful grabbing a partner, partner up
      set partnered? true
      set heading 270                   ;;face partner
      ask partner [
        set partnered? true
        set partner myself
        set heading 90
      ]
    ]
  ]
end

;;choose an action based upon the strategy being played
to select-action ;;turtle procedure
  if strategy = "cooperator" [ cooperator ]
  if strategy = "random" [ act-randomly ]
  if strategy = "defector" [ defector ]
  if strategy = "unforgiving" [ unforgiving ]
  if strategy = "tit-for-tat" [ tit-for-tat ]
  if strategy = "discriminating-altruist" [ discriminating-altruist ]
  if strategy = "win-stay-lose-shift" [ win-stay-lose-shift ]
  if strategy = "true-believer" [ true-believer ]
  if strategy = "opportunist" [ opportunist ]
  if strategy = "no-interaction" [ no-interaction ]
end

;;update PARTNER-HISTORY based upon the strategy being played
to update-history
  if strategy = "cooperator" [ cooperator-history-update ]
  if strategy = "random" [ random-history-update ]
  if strategy = "defector" [ defector-history-update ]
  if strategy = "unforgiving" [ unforgiving-history-update ]
  if strategy = "tit-for-tat" [ tit-for-tat-history-update ]
  if strategy = "discriminating-altruist" [ discriminating-altruist-history-update ]
  if strategy = "win-stay-lose-shift" [ win-stay-lose-shift-history-update ]
  if strategy = "true-believer" [ true-believer-history-update ]
  if strategy = "opportunist" [ opportunist-history-update ]
  if strategy = "no-interaction" [ no-interaction-history-update ]
end

to get-payoff
  set totalpayoff totalpayoff + payoff
  if totalpayoff >= 100 [ set hatch-chance 100 set totalpayoff totalpayoff - 100 ]
  if totalpayoff <= -100 [ set die-chance 100 set totalpayoff totalpayoff + 100 ]
end

;;;;;;;;;;;;;;;;
;;;Strategies;;;
;;;;;;;;;;;;;;;;

;;All the strategies are described in the Info tab.

to cooperator
  set num-cooperator-games num-cooperator-games + 1
  ask partner [
    set partner-strategy "cooperator"
    set partner-action "cooperating"
  ]
  if partner-strategy = "cooperator" [ set payoff C ]
  if partner-strategy = "random" [
    if partner-action = "cooperating" [ set payoff C ]
    if partner-action = "cheating" [ set payoff (- R) ]
  ]
  if partner-strategy = "defector" [ set payoff (- R) ]
  if partner-strategy = "unforgiving" [ set payoff C ]
  if partner-strategy = "tit-for-tat" [ set payoff C ]
  if partner-strategy = "discriminating-altruist" [ set payoff C ]
  if partner-strategy = "win-stay-lose-shift" [ set payoff C ]
  if partner-strategy = "true-believer" [ set payoff C ]
  if partner-strategy = "opportunist" [ set payoff (- R) ]
  if partner-strategy = "no-interaction" [ set payoff 0 ]
end

to cooperator-history-update
;;uses no history- this is just for similarity with the other strategies
end

to act-randomly
  set num-random-games num-random-games + 1
  ask partner [ set partner-strategy "random" ]
  ifelse random 100 < 50 [
    ask partner [ set partner-action "cooperating" ]
    if partner-strategy = "cooperator" [ set payoff C ]
    if partner-strategy = "random" [
      if partner-action = "cooperating" [ set payoff C ]
      if partner-action = "cheating" [ set payoff (- R) ]
    ]
    if partner-strategy = "defector" [ set payoff (- R) ]
    if partner-strategy = "unforgiving" [ set payoff C ]
    if partner-strategy = "tit-for-tat" [ set payoff C ]
    if partner-strategy = "discriminating-altruist" [ set payoff C ]
    if partner-strategy = "win-stay-lose-shift" [
      if partner-action = "cooperating" [ set payoff C ]
      if partner-action = "cheating" [ set payoff (- R) ]
    ]
    if partner-strategy = "true-believer" [ set payoff C ]
    if partner-strategy = "opportunist" [ set payoff (- R) ]
    if partner-strategy = "no-interaction" [ set payoff 0 ]
  ] [
    ask partner [ set partner-action "cheating" ]
    if partner-strategy = "cooperator" [ set payoff R ]
    if partner-strategy = "random" [
      if partner-action = "cooperating" [ set payoff R ]
      if partner-action = "cheating" [ set payoff (- F * P) ]
    ]
    if partner-strategy = "defector" [ set payoff (- F * P) ]
    if partner-strategy = "unforgiving" [
      if partner-action = "cooperating" [ set payoff R ]
      if partner-action = "cheating" [ set payoff (- F * P) ]
    ]
    if partner-strategy = "tit-for-tat" [
      if partner-action = "cooperating" [ set payoff R ]
      if partner-action = "cheating" [ set payoff (- F * P) ]
    ]
    if partner-strategy = "discriminating-altruist" [
      if partner-action = "cooperating" [ set payoff R ]
      if partner-action = "no-interaction" [ set payoff 0 ]
    ]
    if partner-strategy = "win-stay-lose-shift" [
      if partner-action = "cooperating" [ set payoff R ]
      if partner-action = "cheating" [ set payoff (- F * P) ]
    ]
    if partner-strategy = "true-believer" [
      if partner-action = "cooperating" [ set payoff R ]
      if partner-action = "cheating" [ set payoff (- F * P) ]
    ]
    if partner-strategy = "opportunist" [ set payoff (A * R) ]
    if partner-strategy = "no-interaction" [ set payoff 0 ]
  ]
end

to random-history-update
;;uses no history- this is just for similarity with the other strategies
end

to defector
  set num-defector-games num-defector-games + 1
  ask partner [
    set partner-strategy "defector"
    set partner-action "cheating"
  ]
  if partner-strategy = "cooperator" [ set payoff R ]
  if partner-strategy = "random" [
    if partner-action = "cooperating" [ set payoff R ]
    if partner-action = "cheating" [ set payoff (- F * P) ]
  ]
  if partner-strategy = "defector" [ set payoff (- F * P) ]
  if partner-strategy = "unforgiving" [
    if partner-action = "cooperating" [ set payoff R ]
    if partner-action = "cheating" [ set payoff (- F * P) ]
  ]
  if partner-strategy = "tit-for-tat" [
    if partner-action = "cooperating" [ set payoff R ]
    if partner-action = "cheating" [ set payoff (- F * P) ]
  ]
  if partner-strategy = "discriminating-altruist" [
    if partner-action = "cooperating" [ set payoff R ]
    if partner-action = "no-interaction" [ set payoff 0 ]
  ]
  if partner-strategy = "win-stay-lose-shift" [
    if partner-action = "cooperating" [ set payoff R ]
    if partner-action = "cheating" [ set payoff (- F * P) ]
  ]
  if partner-strategy = "true-believer" [
    if partner-action = "cooperating" [ set payoff R ]
    if partner-action = "cheating" [ set payoff (- F * P) ]
  ]
  if partner-strategy = "opportunist" [ set payoff (A * R) ]
  if partner-strategy = "no-interaction" [ set payoff 0 ]
end

to defector-history-update
;;uses no history- this is just for similarity with the other strategies
end

to unforgiving
  set num-unforgiving-games num-unforgiving-games + 1
  ask partner [ set partner-strategy "unforgiving" ]
  set partner-actioned item ([who] of partner) partner-history
  ifelse partner-actioned = "cheating"
    [ ask partner [ set partner-action "cheating" ] ]
    [ ask partner [ set partner-action "cooperating" ] ]
  if partner-strategy = "cooperator" [ set payoff C ]
  if partner-strategy = "random" [
    ifelse partner-actioned = "cheating" [
      ifelse partner-action = "cheating"
        [ set payoff (- F * P) ]
        [ set payoff R ]
    ] [
      ifelse partner-action = "cheating"
        [ set payoff (- R) ]
        [ set payoff C ]
    ]
  ]
  if partner-strategy = "defector" [
    ifelse partner-actioned = "cheating"
      [ set payoff (- F * P) ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "unforgiving" [ set payoff C ]
  if partner-strategy = "tit-for-tat" [ set payoff C ]
  if partner-strategy = "discriminating-altruist" [ set payoff C ]
  if partner-strategy = "win-stay-lose-shift" [ set payoff C ]
  if partner-strategy = "true-believer" [ set payoff C ]
  if partner-strategy = "opportunist" [
    ifelse partner-actioned = "cheating"
      [ set payoff (A * R) ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "no-interaction" [ set payoff 0 ]
end

to unforgiving-history-update
  set partner-actioned partner-action
  if partner-actioned = "cheating" [
    set partner-history
      (replace-item ([who] of partner) partner-history partner-actioned)
  ]
end

to tit-for-tat
  set num-tit-for-tat-games num-tit-for-tat-games + 1
  ask partner [ set partner-strategy "tit-for-tat" ]
  set partner-actioned item ([who] of partner) partner-history
  ifelse partner-actioned = "cheating"
    [ ask partner [ set partner-action "cheating" ] ]
    [ ask partner [ set partner-action "cooperating" ] ]
  if partner-strategy = "cooperator" [ set payoff C ]
  if partner-strategy = "random" [
    ifelse partner-actioned = "cheating" [
      ifelse partner-action = "cheating"
        [ set payoff (- F * P) ]
        [ set payoff R ]
    ] [
      ifelse partner-action = "cheating"
        [ set payoff (- R) ]
        [ set payoff C ]
    ]
  ]
  if partner-strategy = "defector" [
    ifelse partner-actioned = "cheating"
      [ set payoff (- F * P) ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "unforgiving" [ set payoff C ]
  if partner-strategy = "tit-for-tat" [ set payoff C ]
  if partner-strategy = "discriminating-altruist" [ set payoff C ]
  if partner-strategy = "win-stay-lose-shift" [ set payoff C ]
  if partner-strategy = "true-believer" [ set payoff C ]
  if partner-strategy = "opportunist" [
    ifelse partner-actioned = "cheating"
      [ set payoff (A * R) ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "no-interaction" [ set payoff 0 ]
end

to tit-for-tat-history-update
  set partner-actioned partner-action
  set partner-history
    (replace-item ([who] of partner) partner-history partner-actioned)
end

to discriminating-altruist
  set num-discriminating-altruist-games num-discriminating-altruist-games + 1
  ask partner [ set partner-strategy "discriminating-altruist" ]
  set partner-actioned item ([who] of partner) partner-history
  ifelse partner-actioned = "cheating"
    [ ask partner [ set partner-action "no-interaction" ] ]
    [ ask partner [ set partner-action "cooperating" ] ]
  if partner-strategy = "cooperator" [ set payoff C ]
  if partner-strategy = "random" [
    ifelse partner-actioned = "cheating" [
      set payoff 0
    ] [
      ifelse partner-action = "cheating"
        [ set payoff (- R) ]
        [ set payoff C ]
    ]
  ]
  if partner-strategy = "defector" [
    ifelse partner-actioned = "cheating"
      [ set payoff 0 ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "unforgiving" [ set payoff C ]
  if partner-strategy = "tit-for-tat" [ set payoff C ]
  if partner-strategy = "discriminating-altruist" [ set payoff C ]
  if partner-strategy = "win-stay-lose-shift" [ set payoff C ]
  if partner-strategy = "true-believer" [ set payoff C ]
  if partner-strategy = "opportunist" [
    ifelse partner-actioned = "cheating"
      [ set payoff 0 ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "no-interaction" [ set payoff 0 ]
end

to discriminating-altruist-history-update
  set partner-actioned partner-action
  if partner-actioned = "cheating" [
    set partner-history
      (replace-item ([who] of partner) partner-history partner-actioned)
  ]
end

to win-stay-lose-shift
  set num-win-stay-lose-shift-games num-win-stay-lose-shift-games + 1
  ask partner [ set partner-strategy "win-stay-lose-shift" ]
  let self-action "cooperating"
  set partner-actioned item ([who] of partner) partner-history
  if partner-strategy = "cooperator" [
    ask partner [ set partner-action "cooperating" ]
    set payoff C
  ]
  if partner-strategy = "random" [
    if partner-actioned = "false" [
      ask partner [ set partner-action "cooperating" ]
      set self-action "cooperating"
    ]
    if partner-actioned = (- F * P) [
      ask partner [ set partner-action "cooperating" ]
      set self-action "cooperating"
    ]
    if partner-actioned = R [
      ask partner [ set partner-action "cheating" ]
      set self-action "cheating"
    ]
    if partner-actioned = (- R) [
      ask partner [ set partner-action "cheating" ]
      set self-action "cheating"
    ]
    if partner-actioned = C [
      ask partner [ set partner-action "cooperating" ]
      set self-action "cooperating"
    ]
    ifelse self-action = "cheating" [
      ifelse partner-action = "cheating"
        [ set payoff (- F * P) ]
        [ set payoff R ]
    ] [
      ifelse partner-action = "cheating"
        [ set payoff (- R) ]
        [ set payoff C ]
    ]
  ]
  if partner-strategy = "defector" [
    if partner-actioned = "false" [
      ask partner [ set partner-action "cooperating" ]
      set self-action "cooperating"
    ]
    if partner-actioned = (- F * P) [
      ask partner [ set partner-action "cooperating" ]
      set self-action "cooperating"
    ]
    if partner-actioned = (- R) [
      ask partner [ set partner-action "cheating" ]
      set self-action "cheating"
    ]
    ifelse self-action = "cheating"
      [ set payoff (- F * P) ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "unforgiving" [
    ask partner [ set partner-action "cooperating" ]
    set payoff C
  ]
  if partner-strategy = "tit-for-tat" [
    ask partner [ set partner-action "cooperating" ]
    set payoff C
  ]
  if partner-strategy = "discriminating-altruist" [
    ask partner [ set partner-action "cooperating" ]
    set payoff C
  ]
  if partner-strategy = "win-stay-lose-shift" [
    ask partner [ set partner-action "cooperating" ]
    set payoff C
  ]
  if partner-strategy = "true-believer" [
    ask partner [ set partner-action "cooperating" ]
    set payoff C
  ]
  if partner-strategy = "opportunist" [
    if partner-actioned = "false" [
      ask partner [ set partner-action "cooperating" ]
      set self-action "cooperating"
    ]
    if partner-actioned = (A * R) [
      ask partner [ set partner-action "cheating" ]
      set self-action "cheating"
    ]
    if partner-actioned = (- R) [
      ask partner [ set partner-action "cheating" ]
      set self-action "cheating"
    ]
    ifelse self-action = "cheating"
      [ set payoff (A * R) ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "no-interaction" [
    ask partner [ set partner-action "cooperating" ]
    set payoff 0
  ]
end

to win-stay-lose-shift-history-update
  set partner-history
    (replace-item ([who] of partner) partner-history payoff)
end

to true-believer
  set num-true-believer-games num-true-believer-games + 1
  ask partner [ set partner-strategy "true-believer" ]
  set partner-actioned item ([who] of partner) partner-history
  ifelse partner-actioned = "cheating"
    [ ask partner [ set partner-action "cheating" ] ]
    [ ask partner [ set partner-action "cooperating" ] ]
  if partner-strategy = "cooperator" [ set payoff C ]
  if partner-strategy = "random" [
    ifelse partner-actioned = "cheating" [
      ifelse partner-action = "cheating"
        [ set payoff (- F * P) ]
        [ set payoff R ]
    ] [
      ifelse partner-action = "cheating"
        [ set payoff (- R) ]
        [ set payoff C ]
    ]
  ]
  if partner-strategy = "defector" [
    ifelse partner-actioned = "cheating"
      [ set payoff (- F * P) ]
      [ set payoff (- R) ]
  ]
  if partner-strategy = "unforgiving" [ set payoff C ]
  if partner-strategy = "tit-for-tat" [ set payoff C ]
  if partner-strategy = "discriminating-altruist" [ set payoff C ]
  if partner-strategy = "win-stay-lose-shift" [ set payoff C ]
  if partner-strategy = "true-believer" [ set payoff C ]
  if partner-strategy = "opportunist" [ set payoff (A * C) ]
  if partner-strategy = "no-interaction" [ set payoff 0 ]
end

to true-believer-history-update
  set partner-actioned partner-action
  if partner-actioned = "cheating" [
    set partner-history
      (replace-item ([who] of partner) partner-history partner-actioned)
  ]
end

to opportunist
  set num-opportunist-games num-opportunist-games + 1
  ask partner [ set partner-strategy "opportunist" ]
  if partner-strategy = "cooperator" [
    ask partner [ set partner-action "cheating" ]
    set payoff R
  ]
  if partner-strategy = "random" [
    ifelse partner-action = "cheating" [
      ask partner [ set partner-action "appeasement-with-cheating" ]
      set payoff (- A * R)
    ] [
      ask partner [ set partner-action "cheating" ]
      set payoff R
    ]
  ]
  if partner-strategy = "defector" [
    ask partner [ set partner-action "appeasement-with-cheating" ]
    set payoff (- A * R)
  ]
  if partner-strategy = "unforgiving" [
    ifelse partner-action = "cooperating" [
      ask partner [ set partner-action "cheating" ]
      set payoff R
    ] [
      ask partner [ set partner-action "appeasement-with-cheating" ]
      set payoff (- A * R)
    ]
  ]
  if partner-strategy = "tit-for-tat" [
    ifelse partner-action = "cooperating" [
      ask partner [ set partner-action "cheating" ]
      set payoff R
    ] [
      ask partner [ set partner-action "appeasement-with-cheating" ]
      set payoff (- A * R)
    ]
  ]
  if partner-strategy = "discriminating-altruist" [
    ifelse partner-action = "cooperating" [
      ask partner [ set partner-action "cheating" ]
      set payoff R
    ] [
      ask partner [ set partner-action "no-interaction" ]
      set payoff 0
    ]
  ]
  if partner-strategy = "win-stay-lose-shift" [
    ifelse partner-action = "cooperating" [
      ask partner [ set partner-action "cheating" ]
      set payoff R
    ] [
      ask partner [ set partner-action "appeasement-with-cheating" ]
      set payoff (- A * R)
    ]
  ]
  if partner-strategy = "true-believer" [
    ifelse partner-action = "cooperating" [
      ask partner [ set partner-action "cheating" ]
      set payoff R
    ] [
      ask partner [ set partner-action "appeasement-with-cheating" ]
      set payoff (- A * R)
    ]
  ]
  if partner-strategy = "opportunist" [
    ask partner [ set partner-action "no-interaction" ]
    set payoff 0
  ]
  if partner-strategy = "no-interaction" [
    ask partner [ set partner-action "no-interaction" ]
    set payoff 0
  ]
end

to opportunist-history-update
;;uses no history- this is just for similarity with the other strategies
end

to no-interaction
  set num-no-interaction-games num-no-interaction-games + 1
  ask partner [ set partner-strategy "no-interaction" ]
  ask partner [ set partner-action "no-interaction" ]
  set payoff 0
end

to no-interaction-history-update
;;uses no history- this is just for similarity with the other strategies
end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plotting Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;;calculate the total populations of each strategy
to do-population
  set cooperator-population  (calc-population "cooperator" num-cooperator)
  set random-population  (calc-population "random" num-random)
  set defector-population  (calc-population "defector" num-defector)
  set unforgiving-population  (calc-population "unforgiving" num-unforgiving)
  set tit-for-tat-population  (calc-population "tit-for-tat" num-tit-for-tat)
  set discriminating-altruist-population  (calc-population "discriminating-altruist" num-discriminating-altruist)
  set win-stay-lose-shift-population  (calc-population "win-stay-lose-shift" num-win-stay-lose-shift)
  set true-believer-population  (calc-population "true-believer" num-true-believer)
  set opportunist-population  (calc-population "opportunist" num-opportunist)
  set no-interaction-population  (calc-population "no-interaction" num-no-interaction)
end

;; returns the total population for a strategy if any turtles exist that are playing it
to-report calc-population [strategy-type num-with-strategy]
  let num-turtles count turtles with [ hidden? = false ]
  ifelse num-with-strategy > 0 and num-turtles > 0 [
    report ( count (turtles with [ hidden? = false and strategy = strategy-type ] ) / num-turtles * 100  )
  ] [
    report 0
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
365
10
906
552
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
7
10
70
43
setup
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
7
43
179
76
n-cooperator
n-cooperator
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
7
109
179
142
n-defector
n-defector
0
10
10.0
1
1
NIL
HORIZONTAL

BUTTON
70
10
133
43
go
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

BUTTON
133
10
207
43
go once
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

SLIDER
6
175
178
208
n-tit-for-tat
n-tit-for-tat
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
6
208
179
241
n-discriminating-altruist
n-discriminating-altruist
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
6
241
178
274
n-win-stay-lose-shift
n-win-stay-lose-shift
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
6
274
178
307
n-true-believer
n-true-believer
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
6
307
178
340
n-opportunist
n-opportunist
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
7
76
179
109
n-random
n-random
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
6
340
178
373
n-no-interaction
n-no-interaction
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
7
142
179
175
n-unforgiving
n-unforgiving
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
178
43
350
76
C
C
0
0.5
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
179
76
351
109
R
R
C
P
0.5
0.01
1
NIL
HORIZONTAL

PLOT
6
407
302
608
Percent of Population
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"cooperator" 1.0 0 -13345367 true "" "if num-cooperator-games > 0 [ plot cooperator-population ]"
"random" 1.0 0 -7500403 true "" "if num-random-games > 0 [ plot random-population ]"
"defector" 1.0 0 -2674135 true "" "if num-defector-games > 0 [ plot defector-population ]"
"unforgiving" 1.0 0 -14835848 true "" "if num-unforgiving-games > 0 [ plot unforgiving-population ]"
"tit-for-tat" 1.0 0 -13840069 true "" "if num-tit-for-tat-games > 0 [ plot tit-for-tat-population ]"
"discriminating-altruist" 1.0 0 -5825686 true "" "if num-discriminating-altruist-games > 0 [ plot discriminating-altruist-population ]"
"win-stay-lose-shift" 1.0 0 -2064490 true "" "if num-win-stay-lose-shift-games > 0 [ plot win-stay-lose-shift-population ]"
"true-believer" 1.0 0 -6459832 true "" "if num-true-believer-games > 0 [ plot true-believer-population ]"
"opportunist" 1.0 0 -1184463 true "" "if num-opportunist-games > 0 [ plot opportunist-population ]"
"no-interaction" 1.0 0 -11221820 true "" "if num-no-interaction-games > 0 [ plot no-interaction-population ]"

SLIDER
179
109
351
142
P
P
R
1
0.75
0.01
1
NIL
HORIZONTAL

SLIDER
179
142
351
175
A
A
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
178
175
350
208
F
F
1
10
5.0
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
NetLogo 6.1.1
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
