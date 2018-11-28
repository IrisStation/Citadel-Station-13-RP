#if !defined(USING_MAP_DATUM)

	#include "sand_circles.dmm"
	#include "sand_circles_defines.dm"
	#include "sand_circles_areas.dm"
	#include "hadragua.dm"
	//#include "sand_circles_shuttles.dm"

	#define USING_MAP_DATUM /datum/map/sand_circles

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Sand Circles

#endif