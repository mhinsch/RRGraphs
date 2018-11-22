# this package provides some nice convenience syntax 
# for parameters
using Parameters

@with_kw struct Params
	# the macro will move the default values into the constructor
	rand_seed		:: Int		= 113

	n_resources 	:: Int 		= 1 

	xsize 			:: Int 		= 1025
	ysize 			:: Int 		= 1025
	n_cities		:: Int		= 100
	link_thresh		:: Float64	= 0.2
	hurst			:: Float64	= 0.5

	n_start_pos 	:: Int 		= 3
	rate_dep	 	:: Float64	= 0.5

	# default, city, link
	friction					= [0.0, 0.2, 0.1]
	frict_map_range :: Float64 	= 1.0
	control						= [0.2, 0.8, 0.5]
	info 						= [0.1, 0.8, 0.5]
	resources					= [0.0, 0.8, 0.2]
	opacity						= [0.2, 0.6, 0.2]

	# *** quality 
	# friction, control, info, resources...
	weights 		 			= [0.7, 0.5, 0.5, 0.5]
	weights_target 	 			= [0.1, 0.5, 0.5, 0.5]
	qual_boring		:: Float64	= 0.3
	min_target_quality			= 0.5

	# *** info exchange
	# friction, control, info, resources...
	intr_expctd					= [0.5 0.2 0.1 0.0; # default
								   0.2 0.5 0.5 0.5; # city
								   0.2 0.3 0.2 0.0] # link
	intr_steep					= [0.2, 0.1, 0.3, 0.2]
	look_back		:: Int		= 20
	too_far 		:: Int		= 100
	max_mem			:: Int		= 5000
	move_learn		:: Float64	= 0.3

	n_ini_contacts	:: Int		= 10
	ini_capital 	:: Float64 	= 2000.0
	costs_stay		:: Float64	= 1.0
	ben_resources	:: Float64	= 5.0
	costs_move		:: Float64	= 2.0

	p_keep_contact 	:: Float64 	= 0.5
	p_info_mingle	:: Float64	= 0.3
	p_info_contacts	:: Float64	= 0.2
	p_transfer_info	:: Float64	= 0.3

end

