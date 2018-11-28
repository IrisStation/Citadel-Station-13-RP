var/datum/planet/hadragua/planet_hadragua = null

/datum/planet/hadragua
	name = "Hadragua 2"
	desc = "Hadragua 2, the second planet from the Vuolea's system star, is comprised primarily of dunes, deserts, and the occasional small sea. \
	Given that this is the only reasonably habitable planet in the entire system, it is rightly considered its capital planet."
	current_time = new /datum/time/hadragua()
	planetary_wall_type = /turf/unsimulated/wall/planetary/normal
	sun_name = "Vuolea"
	expected_z_levels = list(
		Z_LEVEL_SUB_BEACH,
		Z_LEVEL_MAIN_PLATEAU,
		Z_LEVEL_TOP_CLIFFS
		)
	sun_process_interval = 10 MINUTES

/datum/planet/hadragua/New()
	..()
	planet_hadragua = src
	weather_holder = new /datum/weather_holder/hadragua(src)

//Shamelessly copied from sif.dm because I'm not very creative
/datum/planet/hadragua/update_sun()
	..()
	var/datum/time/time = current_time
	var/length_of_day = time.seconds_in_day / 10 / 60 / 60
	var/noon = length_of_day / 2
	var/distance_from_noon = abs(text2num(time.show_time("hh")) - noon)
	sun_position = distance_from_noon / noon
	sun_position = abs(sun_position - 1)

	var/low_brightness = null
	var/high_brightness = null
	var/low_color = null
	var/high_color = null
	var/min = 0

	switch(sun_position)
		if(0 to 0.40) // Night
			low_brightness = 0.2
			low_color = "#000066"
			high_brightness = 0.5
			high_color = "#66004D"
			min = 0

		if(0.40 to 0.50) // Twilight
			low_brightness = 0.6
			low_color = "#66004D"

			high_brightness = 0.8
			high_color = "#CC3300"
			min = 0.40

		if(0.50 to 0.70) // Sunrise/set
			low_brightness = 0.8
			low_color = "#CC3300"

			high_brightness = 0.9
			high_color = "#FF9933"
			min = 0.50

		if(0.70 to 1.00) // Noon
			low_brightness = 0.9
			low_color = "#DDDDDD"

			high_brightness = 1.0
			high_color = "#FFFFFF"
			min = 0.70

	var/lerp_weight = (abs(min - sun_position)) * 4
	var/weather_light_modifier = 1
	if(weather_holder && weather_holder.current_weather)
		weather_light_modifier = weather_holder.current_weather.light_modifier

	var/new_brightness = (Interpolate(low_brightness, high_brightness, weight = lerp_weight) ) * weather_light_modifier

	var/new_color = null
	if(weather_holder && weather_holder.current_weather && weather_holder.current_weather.light_color)
		new_color = weather_holder.current_weather.light_color
	else
		var/list/low_color_list = hex2rgb(low_color)
		var/low_r = low_color_list[1]
		var/low_g = low_color_list[2]
		var/low_b = low_color_list[3]

		var/list/high_color_list = hex2rgb(high_color)
		var/high_r = high_color_list[1]
		var/high_g = high_color_list[2]
		var/high_b = high_color_list[3]

		var/new_r = Interpolate(low_r, high_r, weight = lerp_weight)
		var/new_g = Interpolate(low_g, high_g, weight = lerp_weight)
		var/new_b = Interpolate(low_b, high_b, weight = lerp_weight)

		new_color = rgb(new_r, new_g, new_b)

	spawn(1)
		update_sun_deferred(2, new_brightness, new_color)

/datum/time/hadragua
	seconds_in_day = 60 * 60 * 10 * 3

/proc/get_hadragua_time()
	if(planet_hadragua)
		return planet_hadragua.current_time

/datum/weather_holder/hadragua
	temperature = T0C
	allowed_weather_types = list(
		WEATHER_CLEAR		= new /datum/weather/hadragua/clear(),
		WEATHER_OVERCAST	= new /datum/weather/hadragua/overcast(),
		WEATHER_RAIN		= new /datum/weather/hadragua/rain(),
		)
	roundstart_weather_chances = list(
		WEATHER_CLEAR		= 30,
		WEATHER_OVERCAST	= 30,
		WEATHER_RAIN		= 5,
		)

/datum/weather/hadragua
	name = "hadragua base"
	temp_high = 299.817	// 80f
	temp_low = 288.706	// 60f

/datum/weather/hadragua/clear
	name = "clear"
	transition_chances = list(
		WEATHER_CLEAR = 60,
		WEATHER_OVERCAST = 40
		)
	transition_messages = list(
		"The sky clears up.",
		"The sky is visible.",
		"The weather is calm."
		)
	sky_visible = TRUE
	observed_message = "The sky is clear."

/datum/weather/hadragua/overcast
	name = "overcast"
	light_modifier = 0.8
	transition_chances = list(
		WEATHER_CLEAR = 25,
		WEATHER_OVERCAST = 50,
		WEATHER_RAIN = 5,
		)
	observed_message = "It is overcast, all you can see are clouds."
	transition_messages = list(
		"All you can see above are clouds.",
		"Clouds cut off your view of the sky.",
		"It's very cloudy."
		)

/datum/weather/hadragua/rain
	name = "rain"
	icon_state = "rain"
	light_modifier = 0.5
	effect_message = "<span class='warning'>Rain falls on you.</span>"

	transition_chances = list(
		WEATHER_OVERCAST = 25,
		WEATHER_RAIN = 50,
		)
	observed_message = "It is raining."
	transition_messages = list(
		"The sky is dark, and rain falls down upon you."
	)

/datum/weather/hadragua/rain/process_effects()
	..()
	for(var/mob/living/L in living_mob_list)
		if(L.z in holder.our_planet.expected_z_levels)
			var/turf/T = get_turf(L)
			if(!T.outdoors)
				continue // They're indoors, so no need to rain on them.

			// If they have an open umbrella, it'll guard from rain
			if(istype(L.get_active_hand(), /obj/item/weapon/melee/umbrella))
				var/obj/item/weapon/melee/umbrella/U = L.get_active_hand()
				if(U.open)
					if(show_message)
						to_chat(L, "<span class='notice'>Rain patters softly onto your umbrella.</span>")
					continue
			else if(istype(L.get_inactive_hand(), /obj/item/weapon/melee/umbrella))
				var/obj/item/weapon/melee/umbrella/U = L.get_inactive_hand()
				if(U.open)
					if(show_message)
						to_chat(L, "<span class='notice'>Rain patters softly onto your umbrella.</span>")
					continue

			L.water_act(1)
			if(show_message)
				to_chat(L, effect_message)