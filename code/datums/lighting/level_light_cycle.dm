// Day/night lighting cycle for planetary z-levels
// Chains animate() calls for the full cycle, then re-queues via addtimer

/datum/level_lighting_cycle
	var/list/phase_colors
	var/cycle_duration
	var/start_offset
	var/datum/space_level/managed_level
	var/timer_id
	var/resume_timer_id
	var/paused = FALSE

/datum/level_lighting_cycle/snow
	phase_colors = list("#363b4c", "#ebfffa", "#806963", "#13131f") // dawn, day, sunset, night
	cycle_duration = 36000 // 60 MINUTES

/datum/level_lighting_cycle/forest
	phase_colors = list("#4a6741", "#8fbf6f", "#c47a4a", "#1a2a1a") // dawn, day, sunset, night
	cycle_duration = 36000 // 60 MINUTES

/datum/level_lighting_cycle/desert
	phase_colors = list("#8a6a4a", "#f0d8a0", "#c45030", "#1a1a2f") // dawn, day, sunset, night
	cycle_duration = 36000 // 60 MINUTES

/datum/level_lighting_cycle/New(datum/space_level/SL)
	managed_level = SL
	start_offset = rand(0, cycle_duration - 1)

/datum/level_lighting_cycle/Destroy()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	if(resume_timer_id)
		deltimer(resume_timer_id)
		resume_timer_id = null
	managed_level = null
	return ..()

/datum/level_lighting_cycle/proc/get_phase_duration()
	return cycle_duration / length(phase_colors)

// Queue the full animate() chain from current time position, then schedule re-queue
/datum/level_lighting_cycle/proc/apply()
	if(!managed_level || managed_level.color_holder.locked || paused)
		return

	var/phase_duration = get_phase_duration()
	var/pos = (world.time + start_offset) % cycle_duration
	var/phase_count = length(phase_colors)
	var/cur_phase = clamp(round(pos / phase_duration), 0, phase_count - 1) // 0-indexed
	var/progress = (pos % phase_duration) / phase_duration

	var/cur_color = phase_colors[cur_phase + 1]
	var/next_phase = (cur_phase + 1) % phase_count
	var/next_color = phase_colors[next_phase + 1]

	// snap to exact interpolated position
	var/snap_color = BlendRGB(cur_color, next_color, progress)
	var/remaining_time = phase_duration * (1 - progress)

	// stop any existing animation
	animate(managed_level.color_holder, time = 0, color = snap_color, flags = ANIMATION_END_NOW)

	// transition to end of current phase
	animate(managed_level.color_holder, time = remaining_time, color = next_color, flags = ANIMATION_CONTINUE)
	var/total_queued = remaining_time

	// chain remaining phases to complete the cycle
	for(var/i in 1 to phase_count - 1)
		var/idx = ((next_phase + i) % phase_count) + 1
		animate(managed_level.color_holder, time = phase_duration, color = phase_colors[idx], flags = ANIMATION_CONTINUE)
		total_queued += phase_duration

	// schedule re-queue to loop
	if(timer_id)
		deltimer(timer_id)
	timer_id = addtimer(CALLBACK(src, PROC_REF(apply)), total_queued, TIMER_STOPPABLE)

/datum/level_lighting_cycle/proc/pause()
	paused = TRUE
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	if(resume_timer_id)
		deltimer(resume_timer_id)
		resume_timer_id = null

/datum/level_lighting_cycle/proc/resume()
	paused = FALSE
	apply()
