; -------------------------------------------
;                  TEMPLATES
; -------------------------------------------
(deftemplate Call
    (slot id_call (type INTEGER))
    (slot emergency (type STRING))
    (slot attended (type STRING))
    (slot solved (type STRING))
)

(deftemplate Assistance    
    (slot name (type STRING)) 
    (slot location )
    (slot n_units (type INTEGER))
)

(deftemplate EmergencyReport   
    (slot id_call (type INTEGER)) 
    (slot emergency (type STRING))
    (slot location (type STRING))
    (slot Police)
    (slot Sanitaries)
    (slot Firefighters)
    (slot SpecialEquipment)
)

; -------------------------------------------
;                  FACTS
; -------------------------------------------
(deffacts main_facts
    (Call
        (id_call 10)
        (attended "No")
    )

    (Call
        (id_call 12)
        (attended "No")
    )

    (Assistance
        (name "GuardiaCivil")
        (location Norte)
        (n_units 10)
    )
    (Assistance
        (name "Sanitarios")
        (location Norte)
        (n_units 10)
    )
    (Assistance
        (name "Bomberos")
        (location Norte)
        (n_units 8)
    )
    (Assistance
        (name "GuardiaCivil")
        (location Sur)
        (n_units 10)
    )
    (Assistance
        (name "Sanitarios")
        (location Sur)
        (n_units 6)
    )
    (Assistance
        (name "Bomberos")
        (location Sur)
        (n_units 10)
    )
)

; -------------------------------------------
;                  FUNCTIONS
; -------------------------------------------
(deffunction RequireAgents (?n ?p)
    (bind ?result(/ ?n ?p))
    (bind ?rest (mod ?result 1))
    (if (> ?rest 0) then
      (+ (integer ?result) 1)
    else
      (integer ?result)
    )
)

; -------------------------------------------
;                  RULES
; -------------------------------------------
(defrule EmergencyCall
    (Call (id_call ?id) (attended ?a))
    (test (eq ?a "No"))
    =>
    (printout t "-> ¿Cual es su emergencia? Car/Fire/Ninguna" crlf)
    (bind ?emer (read))
    (assert (Emergency ?id  ?emer))
)

; -------- CAR ACCIDENT EMERGENCY --------
(defrule CarAccidentEmergency
    ?e <- (Emergency ?id ?emer)
    ?c <- (Call (id_call ?id))
    (test (eq ?emer Car))
    =>
    (printout t "-> ¿Donde se ha producido el accidente? Norte/Sur" crlf)
    (bind ?loc (read))
    (assert (Notify ?id "GuardiaCivil" ?loc 2))

    (assert (Victims ?id ?emer ?loc))
    (assert (Call (id_call ?id) (emergency ?emer) (attended "Yes")))
    (assert (EmergencyReport (id_call ?id) (emergency ?emer) (location ?loc)))
    (retract ?c)
    (retract ?e)
)

(defrule CarVictims
    ?v <- (Victims ?id ?emer ?loc)
    ?sol <- (EmergencyReport (id_call ?id))
    =>
    (printout t "-> ¿Existen heridos? S/N" crlf)
    (bind ?resp (read))
    (if (or (eq ?resp S)(eq ?resp s))
        then
        (printout t "-> ¿Cuantas personas estan heridas?" crlf)
        (bind ?n (read)) 
        ; Número de agentes
        (bind ?agents(RequireAgents ?n 6))
        (assert (Notify ?id "Sanitarios" ?loc ?agents))
    else
        (bind ?n 0) 
        (modify ?sol(Sanitaries NoNeed))
    )
    (assert (Trapped ?id ?emer ?loc ?n))
    (retract ?v)
)

(defrule TrappedPeople
    ?t <- (Trapped ?id ?emer ?loc ?n)
    ?sol <- (EmergencyReport (id_call ?id))
    =>
    (printout t "-> ¿Hay personas atrapadas? S/N" crlf)
    (bind ?nt (read))
    (if (and (eq ?nt S)(eq ?n 0))
        then
        (printout t "-> ¿Cuantas personas?" crlf)
        (bind ?np (read))

        (bind ?agents(RequireAgents ?np 6))
        (assert (Notify ?id "Sanitarios" ?loc ?agents))
        (assert (Notify ?id "Bomberos" ?loc 1))
    )
    (if (and (eq ?nt S)(neq ?n 0))
        then
        (assert (Notify ?id "Bomberos" ?loc 1))

        else
        (modify ?sol(Firefighters NoNeed))
    )
    (assert (Dangerous ?id))
    (retract ?t)
)

; -------- FIRE EMERGENCY --------
(defrule FireEmergency
    ?e <- (Emergency ?id ?emer)
    ?c <- (Call (id_call ?id))
    (test (eq ?emer Fire))
    =>
    (printout t "-> ¿Donde se ha producido? Norte/Sur" crlf)
    (bind ?loc (read))

    (assert (Call (id_call ?id) (emergency ?emer) (attended "Yes")))
    (assert (EmergencyReport (id_call ?id) (emergency ?emer) (location ?loc) ))
    (assert (Extent ?id ?emer ?loc))
    (retract ?c)
    (retract ?e)
)

(defrule FireExtent
    ?ex <- (Extent ?id ?emer ?loc)
    =>
    (printout t "-> ¿Que es exactamente lo que arde? Vivienda/Edificio-0, Edificios-1" crlf)
    (bind ?ob (read))

    (if (eq ?ob 0) then
        (printout t "-> ¿Cuantas personas?" crlf)
        (bind ?np (read))

        (assert (Notify ?id "GuardiaCivil" ?loc 1))
        (bind ?agents(RequireAgents ?np 6))
        (assert (Notify ?id "Sanitarios" ?loc ?agents))
        (assert (Notify ?id "Bomberos" ?loc 1))
    else
        (printout t "-> ¿Cuantos edificios?" crlf)
        (bind ?e (read))

        (bind ?san(RequireAgents ?e 6))
        (assert (Notify ?id "GuardiaCivil" ?loc ?e))
        (assert (Notify ?id "Sanitarios" ?loc ?san))
        (bind ?fire(RequireAgents ?e 1))
        (assert (Notify ?id "Bomberos" ?loc ?fire))
    )
    
    (assert (Dangerous ?id))
    (retract ?ex)
)

(defrule HazardousGoods
    ?d <- (Dangerous ?id)
    ?sol <- (EmergencyReport (id_call ?id))
    =>
    (printout t "¿Hay algun vehiculo o edificio con mercancias peligrosas? S/N" crlf)
    (bind ?h (read))
    (if (or(eq ?h S)(eq ?h s)) then
        (modify ?sol(SpecialEquipment Needed))
    else
        (modify ?sol(SpecialEquipment NoNeed))
    )
    
    (retract ?d)
)

; -------- FALSE ALARM --------
(defrule FalseAlarm
    ?e <- (Emergency ?id ?emer)
    ?c <- (Call (id_call ?id))
    (test (eq ?emer Ninguna))
    =>
    (printout t "FALSA ALARMA" crlf)

    (assert (Call (id_call ?id) (emergency "FalseAlarm") (attended "Yes") (solved "Yes")))

    (retract ?c)
    (retract ?e)
)

; -------- NOTIFY RESPECTIVE UNITS --------
(defrule InformServices
   ?s <- (Notify ?id ?serv ?loc ?agents)
   ?a <- (Assistance (name ?serv ) (location ?loc) (n_units ?ud))
   ?sol <- (EmergencyReport (id_call ?id))
    =>
    (printout t "Informando " ?serv " del distrito " ?loc crlf)

    (if (>= ?ud ?agents) then
        (bind ?rest(- ?ud ?agents))
        (modify ?a(n_units ?rest))
        (printout t "       Enviando unidades" crlf) 
        (bind ?resp Yes)

    else
        (if (> ?ud 0) then
            (printout t "       No hay tantas unidades disponibles" crlf)
            (bind ?agents(- ?agents ?ud))
            (modify ?a(n_units 0)) 
            (printout t "       Enviando unidades restantes" crlf)
        else
            (printout t "       No hay unidades disponibles" crlf)
        )
        (bind ?resp No)
        (assert (Backup ?id ?serv ?loc ?agents))
    )
    (if (eq ?serv "GuardiaCivil") then (modify ?sol(Police ?resp)))
    (if (eq ?serv "Sanitarios") then (modify ?sol(Sanitaries ?resp)))
    (if (eq ?serv "Bomberos") then (modify ?sol(Firefighters ?resp)))

    (assert (check ?id))
    (retract ?s)
)

(defrule InformBackup
    ?b <- (Backup ?id ?serv ?loc ?agents)
    ?a <- (Assistance (name ?serv) (location ?l) (n_units ?ud))
    ?sol <- (EmergencyReport (id_call ?id))
    (test (neq ?loc ?l))
    =>
    (printout t "Informando Refuerzos " ?serv " del distrito " ?l crlf)

    (if (>= ?ud ?agents) then
        (bind ?rest(- ?ud ?agents))
        (modify ?a(n_units ?rest))
        (printout t "       Enviando unidades" crlf) 
        (bind ?resp Yes)

    else
        (if (> ?ud 0) then
            (printout t "       No hay tantas unidades disponibles" crlf)
            (modify ?a(n_units 0)) 
            (printout t "       Enviando unidades restantes" crlf)
        else
            (printout t "       No hay unidades disponibles" crlf)
        )
        (bind ?resp No)
    )
    (if (eq ?serv "GuardiaCivil") then (modify ?sol(Police ?resp)))
    (if (eq ?serv "Sanitarios") then (modify ?sol(Sanitaries ?resp)))
    (if (eq ?serv "Bomberos") then (modify ?sol(Firefighters ?resp)))
    
    (assert (check ?id))
    (retract ?b)
)

(defrule CheckEmergencyAttended
    ?c <- (check ?id)
    ?sol <- (EmergencyReport (id_call ?id) (Police ?p) (Sanitaries ?s) (Firefighters ?f))
    ?call <- (Call (id_call ?id))
    =>

    (if (or(or (eq ?p No) (eq ?s No)) (eq ?f No)) then 
        (modify ?call(solved "No"))
    else 
        (modify ?call(solved "Yes"))
    )

    (retract ?c)
)