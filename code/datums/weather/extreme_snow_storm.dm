// Extreme snow storm - admin-only event for snow planets
// Hurricane winds push everything, extreme cold kills in seconds, walls get destroyed

/datum/weather/snow_storm/extreme
	name = "extreme snow storm"
	desc = "An apocalyptic blizzard with hurricane-force winds and lethal temperatures."
	probability = 0 // never auto-triggered, admin only

	telegraph_message = "<span class='userdanger'>Снежная буря надвигается! Укройтесь в помещении!</span>"
	telegraph_duration = 3000 // 5 minutes warning
	telegraph_overlay = "light_snow"
	telegraph_sound = 'sound/effects/wind/wind_5_1.ogg'

	weather_message = "<span class='userdanger'><i>ЭКСТРЕМАЛЬНЫЙ ШТОРМ ОБРУШИЛСЯ НА СТАНЦИЮ! Нахождение снаружи смертельно опасно!</i></span>"
	weather_overlay = "snow_storm"
	weather_alpha = 220
	weather_sound = 'sound/effects/wind/wind_5_1.ogg'
	overlay_layer = 10

	end_message = "<span class='boldannounce'>Шторм прекратился. Выход наружу безопасен.</span>"
	end_duration = 100

	additional_action = TRUE
	immunity_type = "extreme_storm"

	var/wind_direction
	var/telegraph_timer_id
	var/tick_counter = 0
	var/list/exterior_walls
	var/next_sound_tick = 5 // randomized interval for ambient sounds

	var/static/list/outdoor_sounds = list(
		'sound/effects/wind/wind_4_1.ogg',
		'sound/effects/wind/wind_4_2.ogg',
		'sound/effects/wind/wind_5_1.ogg'
	)
	var/static/list/indoor_sounds = list(
		'sound/effects/wind/wind_2_1.ogg',
		'sound/effects/wind/wind_2_2.ogg',
		'sound/effects/wind/wind_3_1.ogg'
	)

/datum/weather/snow_storm/extreme/telegraph()
	if(stage == 1)
		return
	stage = 1

	// calculate impacted areas
	var/list/affectareas = get_areas(area_type)
	for(var/V in protected_areas)
		affectareas -= get_areas(V)
	for(var/V in affectareas)
		var/area/A = V
		if(protect_indoors && !A.outdoors)
			continue
		if(SSmapping.level_trait(A.z, target_ztrait))
			impacted_areas |= A

	update_areas()

	// centcom announcement
	var/datum/announcement/centcomm/A = new
	A.message = "ВНИМАНИЕ! Метеорологическая служба зафиксировала экстремальный снежный шторм в вашем секторе. \
		Расчётное время прибытия: 5 минут. Всему персоналу немедленно покинуть наружные зоны и укрыться в герметичных помещениях. \
		Ожидаются ураганный ветер, критически низкие температуры и разрушение внешних конструкций."
	A.play()

	for(var/V in player_list)
		var/mob/M = V
		if(SSmapping.level_trait(M.z, target_ztrait))
			if(telegraph_message)
				to_chat(M, telegraph_message)
			if(telegraph_sound)
				M.playsound_local(null, telegraph_sound, VOL_EFFECTS_MASTER, null, FALSE)

	telegraph_timer_id = addtimer(CALLBACK(src, PROC_REF(start)), telegraph_duration, TIMER_STOPPABLE)

/datum/weather/snow_storm/extreme/start()
	if(stage >= 2)
		return
	stage = 2

	// pick wind direction
	wind_direction = pick(NORTH, SOUTH, EAST, WEST)

	// pre-calculate exterior walls (walls adjacent to outdoor turfs)
	exterior_walls = list()
	for(var/Z in SSmapping.levels_by_trait(target_ztrait))
		for(var/turf/simulated/wall/W in block(locate(1, 1, Z), locate(world.maxx, world.maxy, Z)))
			for(var/dir in global.cardinal)
				var/turf/T = get_step(W, dir)
				if(T)
					var/area/A = get_area(T)
					if(A?.outdoors)
						exterior_walls += W
						break

	update_areas()

	var/wind_name = dir2text(wind_direction)
	for(var/V in player_list)
		var/mob/M = V
		if(SSmapping.level_trait(M.z, target_ztrait))
			to_chat(M, weather_message)
			to_chat(M, "<span class='warning'>Направление ветра: [wind_name].</span>")
			if(weather_sound)
				M.playsound_local(null, weather_sound, VOL_EFFECTS_MASTER, null, FALSE)

	START_PROCESSING(SSweather, src)
	// no wind_down timer — storm is infinite, admin disables manually

/datum/weather/snow_storm/extreme/impact(mob/living/L)
	// extreme cold
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		C.adjust_bodytemperature(-rand(30, 50), use_insulation = TRUE)
	else
		L.adjust_bodytemperature(-rand(30, 50))

	// brute damage from debris
	L.take_overall_damage(rand(1, 3), 0)

	// knockdown every 3 ticks (~3 seconds)
	if(tick_counter % 3 == 0)
		if(iscarbon(L))
			L.Weaken(3)
			var/mob/living/carbon/C = L
			C.drop_l_hand()
			C.drop_r_hand()
			to_chat(L, "<span class='userdanger'>Ураганный ветер сбивает вас с ног!</span>")

	// wind push every 2 ticks (~2 seconds)
	if(tick_counter % 2 == 0)
		step(L, wind_direction)

/datum/weather/snow_storm/extreme/additional_action()
	tick_counter++

	// push unanchored objects every 3 ticks
	if(tick_counter % 3 == 0)
		for(var/area/impact_area as anything in impacted_areas)
			var/list/turfs = get_area_turfs(impact_area, FALSE)
			var/sample_count = max(1, turfs.len / 50)
			for(var/i in 1 to sample_count)
				var/turf/T = pick(turfs)
				for(var/atom/movable/AM in T)
					if(!AM.anchored && !isliving(AM))
						step(AM, wind_direction)

	// wall damage every 10 ticks (~10 seconds)
	if(tick_counter % 10 == 0 && length(exterior_walls))
		for(var/i in length(exterior_walls) to 1 step -1)
			var/turf/W = exterior_walls[i]
			if(!iswallturf(W))
				exterior_walls.Cut(i, i + 1)
				continue
			if(prob(3))
				var/turf/simulated/wall/wall = W
				wall.take_damage(rand(20, 40))

	// ambient sound at randomized intervals (3-7 ticks) to avoid repetitive feel
	if(tick_counter >= next_sound_tick)
		next_sound_tick = tick_counter + rand(3, 7)
		for(var/V in player_list)
			var/mob/M = V
			if(!SSmapping.level_trait(M.z, target_ztrait))
				continue
			var/area/A = get_area(M)
			if(!A)
				continue
			if(A.outdoors)
				M.playsound_local(null, pick(outdoor_sounds), VOL_EFFECTS_MASTER, null, FALSE, channel = CHANNEL_AMBIENT)
			else
				M.playsound_local(null, pick(indoor_sounds), VOL_EFFECTS_MASTER, null, FALSE, channel = CHANNEL_AMBIENT)

/datum/weather/snow_storm/extreme/proc/force_stop()
	if(telegraph_timer_id)
		deltimer(telegraph_timer_id)
		telegraph_timer_id = null
	STOP_PROCESSING(SSweather, src)
	stage = 4
	update_areas()
	impacted_areas = list()
	exterior_walls = null
	tick_counter = 0

	for(var/V in player_list)
		var/mob/M = V
		if(SSmapping.level_trait(M.z, target_ztrait))
			to_chat(M, end_message)
