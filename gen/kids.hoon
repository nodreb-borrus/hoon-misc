::  Generate a list of all child ships seen on the network
::  sorted by last contact time.

:-  %say
|=  [[now=time @ our=@p *] * ~]
:-  %ship
|^
^-  (list peer-qos)
(sort (turn (skim peer-names-all is-child) get-qos) asc)
+$  peer-qos  [p=@p qos=(unit qos:ames)]
++  peer-names-all
  ^-  (list @p)
  %~  tap  in
  %~  key  by
  .^((map ship @tas) %ax /(scot %p our)//(scot %da now)/peers)
++  get-qos
  |=  p=@p
  ^-  peer-qos
  :-  p
  =/  state  .^(ship-state:ames %ax /(scot %p our)//(scot %da now)/peers/(scot %p p))
  ?+  -.state  ~
      %known
    `qos.+.state
  ==
++  is-child
  |=  p=@p
  =(our (sein:title our now p))
++  asc
  |=  [a=peer-qos b=peer-qos]
  ;;  ?
  %^  clef  qos.a  qos.b
  |=  [a=qos:ames b=qos:ames]
  (lth +.a +.b)
--

