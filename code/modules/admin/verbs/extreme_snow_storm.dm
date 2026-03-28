/client/proc/enable_snow_storm()
	set category = "Fun"
	set name = "enable-snow-storm"

	if(!check_rights(R_FUN))
		return

	for(var/datum/weather/snow_storm/extreme/W in SSweather.existing_weather)
		if(W.stage != 4)
			to_chat(usr, "<span class='warning'>Экстремальный шторм уже активен.</span>")
			return

	var/datum/weather/snow_storm/extreme/storm
	for(var/datum/weather/snow_storm/extreme/W in SSweather.existing_weather)
		storm = W
		break

	if(!storm)
		storm = new /datum/weather/snow_storm/extreme

	storm.telegraph()
	log_admin("[key_name(usr)] enabled extreme snow storm.")
	message_admins("<span class='notice'>[key_name_admin(usr)] включил экстремальный снежный шторм.</span>")

/client/proc/disable_snow_storm()
	set category = "Fun"
	set name = "disable-snow-storm"

	if(!check_rights(R_FUN))
		return

	for(var/datum/weather/snow_storm/extreme/W in SSweather.existing_weather)
		if(W.stage != 4)
			W.force_stop()
			log_admin("[key_name(usr)] disabled extreme snow storm.")
			message_admins("<span class='notice'>[key_name_admin(usr)] выключил экстремальный снежный шторм.</span>")
			return

	to_chat(usr, "<span class='warning'>Экстремальный шторм не активен.</span>")
