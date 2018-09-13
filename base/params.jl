using Parameters

# provides nice syntax
@with_kw struct Params
	rand_seed		:: Int		= 123

	xsize 			:: Int 		= 1025
	ysize 			:: Int 		= 1025

	n_start_pos 	:: Int 		= 5
	n_dep_per_step 	:: Int 		= 100

	frict_city 		:: Float64 	= 0.2
	frict_link 		:: Float64 	= 0.1
	frict_map_range :: Float64 	= 1.0
	control_city 	:: Float64 	= 0.8
	control_link 	:: Float64 	= 0.5
	inf_city 		:: Float64 	= 0.8

	n_resources 	:: Int 		= 7

	ini_capital 	:: Float64 	= 100.0

	p_keep_contact 	:: Float64 	= 0.3

end

