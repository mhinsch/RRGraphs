# this package provides some nice convenience syntax 
# for parameters
using Parameters

@with_kw struct Params
	# the macro will move the default values into the constructor
	rand_seed		:: Int		= 123

	xsize 			:: Int 		= 1025
	ysize 			:: Int 		= 1025
	n_cities		:: Int		= 100
	link_thresh		:: Float64	= 0.2

	n_start_pos 	:: Int 		= 5
	n_dep_per_step 	:: Int 		= 10

	frict_city 		:: Float64 	= 0.2
	frict_link 		:: Float64 	= 0.1
	frict_map_range :: Float64 	= 1.0
	control_city 	:: Float64 	= 0.8
	control_link 	:: Float64 	= 0.5
	inf_city 		:: Float64 	= 0.8

	weight_friction	:: Float64	= 0.3
	weight_control	:: Float64	= 0.8
	weight_info		:: Float64	= 0.3

	n_resources 	:: Int 		= 7

	ini_capital 	:: Float64 	= 100.0

	p_keep_contact 	:: Float64 	= 0.3

end

