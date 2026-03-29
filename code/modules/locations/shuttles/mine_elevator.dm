#define ELEVATOR_COOLDOWN 50 // 5 seconds
#define ELEVATOR_MOVE_TIME 30 // 3 seconds

#define ELEVATOR_SURFACE /area/elevator/mining/surface
#define ELEVATOR_UNDERGROUND /area/elevator/mining/underground

/obj/machinery/computer/mine_elevator
	name = "Панель управления лифтом"
	cases = list("панель управления лифтом", "панели управления лифтом", "панели управления лифтом", "панель управления лифтом", "панелью управления лифтом", "панели управления лифтом")
	icon = 'icons/obj/computer.dmi'
	icon_state = "shuttle"
	state_broken_preset = "commb"
	state_nopower_preset = "comm0"
	anchored = TRUE
	density = TRUE

	var/moving = FALSE
	var/lastMove = 0
	var/area/current_location // where the elevator currently is

/obj/machinery/computer/mine_elevator/atom_init()
	. = ..()
	current_location = get_area(src)

/obj/machinery/computer/mine_elevator/ui_interact(mob/user)
	var/location_name
	var/destination_name

	if(istype(current_location, ELEVATOR_SURFACE))
		location_name = "Поверхность"
		destination_name = "Шахта"
	else if(istype(current_location, ELEVATOR_UNDERGROUND))
		location_name = "Шахта"
		destination_name = "Поверхность"
	else
		to_chat(user, "<span class='warning'>Ошибка: лифт не обнаружен.</span>")
		return

	var/seconds = max(round((lastMove + ELEVATOR_COOLDOWN - world.time) * 0.1), 0)
	var/ready = (lastMove + ELEVATOR_COOLDOWN <= world.time) && !moving

	var/dat = ""
	dat += "<h3>Шахтёрский лифт</h3>"
	dat += "<ul>"
	dat += "<li>Текущий уровень: <b>[location_name]</b></li>"
	if(moving)
		dat += "<li>Статус: <b>В движении...</b></li>"
	else if(!ready)
		dat += "<li>Готов через: <b>[seconds] сек.</b></li>"
	else
		dat += "<li>Статус: <b>Готов</b></li>"
	dat += "</ul>"
	dat += "<a href='byond://?src=\ref[src];move=1'>Отправить на уровень: [destination_name]</a>"

	var/datum/browser/popup = new(user, "mine_elevator", "Панель управления лифтом", 350, 200)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/mine_elevator/Topic(href, href_list)
	. = ..()
	if(!.)
		return

	if(href_list["move"])
		try_move(usr)
	updateUsrDialog()

/obj/machinery/computer/mine_elevator/proc/try_move(mob/user)
	if(moving)
		to_chat(user, "<span class='notice'>Лифт уже в движении.</span>")
		return
	if(lastMove + ELEVATOR_COOLDOWN > world.time)
		to_chat(user, "<span class='notice'>Лифт ещё не готов.</span>")
		return

	var/area/destination
	if(istype(current_location, ELEVATOR_SURFACE))
		destination = locate(ELEVATOR_UNDERGROUND)
	else if(istype(current_location, ELEVATOR_UNDERGROUND))
		destination = locate(ELEVATOR_SURFACE)
	else
		return

	if(!destination)
		to_chat(user, "<span class='warning'>Ошибка: пункт назначения не найден.</span>")
		return

	moving = TRUE
	lastMove = world.time

	do_move(current_location, destination)

/obj/machinery/computer/mine_elevator/proc/do_move(area/origin, area/destination)
	// Close doors at current level
	elevator_close_doors(origin)

	// Announce
	for(var/mob/M in origin)
		to_chat(M, "<span class='notice'>Лифт отправляется...</span>")
		M.playsound_local(null, 'sound/machines/synth_alert.ogg', VOL_EFFECTS_MASTER, null, FALSE)

	sleep(10)

	// Shake during departure
	SSshuttle.shake_mobs_in_area(origin, DOWN)

	// Transit time
	sleep(ELEVATOR_MOVE_TIME)

	// Clear destination
	SSshuttle.clean_arriving_area(destination)

	// Move everything
	origin.move_contents_to(destination)

	// Spawn shaft where elevator was, clear shaft where it arrived
	spawn_shaft(origin)
	clear_shaft(destination)

	// Update location
	current_location = destination

	// Arrival shake
	SSshuttle.shake_mobs_in_area(destination, UP)

	// Open doors at new level
	elevator_open_doors(destination)

	// Announce arrival
	for(var/mob/M in destination)
		to_chat(M, "<span class='notice'>Лифт прибыл.</span>")
		M.playsound_local(null, 'sound/machines/ping.ogg', VOL_EFFECTS_MASTER, null, FALSE)

	moving = FALSE

/obj/machinery/computer/mine_elevator/proc/elevator_find_doors(area/A)
	var/list/doors = list()
	for(var/turf/T in A)
		for(var/dir in cardinal)
			var/turf/neighbor = get_step(T, dir)
			if(get_area(neighbor) == A)
				continue
			for(var/obj/machinery/door/D in neighbor)
				if(D.dock_tag == "mining_elevator")
					doors |= D
	return doors

/obj/machinery/computer/mine_elevator/proc/elevator_close_doors(area/A)
	for(var/obj/machinery/door/D in elevator_find_doors(A))
		if(istype(D, /obj/machinery/door/airlock))
			var/obj/machinery/door/airlock/AL = D
			AL.close_unsafe(TRUE)
			AL.bolt()

/obj/machinery/computer/mine_elevator/proc/elevator_open_doors(area/A)
	for(var/obj/machinery/door/D in elevator_find_doors(A))
		if(istype(D, /obj/machinery/door/airlock))
			var/obj/machinery/door/airlock/AL = D
			AL.unbolt()
			AL.open()

/obj/machinery/computer/mine_elevator/proc/spawn_shaft(area/A)
	for(var/turf/T in A)
		new /obj/structure/elevator_shaft(T)

/obj/machinery/computer/mine_elevator/proc/clear_shaft(area/A)
	for(var/turf/T in A)
		for(var/obj/structure/elevator_shaft/S in T)
			qdel(S)

/obj/structure/elevator_shaft
	name = "шахта лифта"
	desc = "Глубокая тёмная шахта. Лучше не падать."
	icon = 'icons/obj/pit.dmi'
	icon_state = "pit1"
	blend_mode = BLEND_MULTIPLY
	anchored = TRUE
	density = TRUE

#undef ELEVATOR_COOLDOWN
#undef ELEVATOR_MOVE_TIME
#undef ELEVATOR_SURFACE
#undef ELEVATOR_UNDERGROUND
