# this package provides some nice convenience syntax 
# for parameters
using Parameters

@with_kw struct Params
	# the macro will move the default values into the constructor
	rand_seed		:: Int		= 113

	n_cities		:: Int		= 100
	link_thresh		:: Float64	= 0.2

	n_start_pos 	:: Int 		= 3
	rate_dep	 	:: Float64	= 0.5
	n_exits			:: Int		= 5

	dist_scale					= [1.0, 10.0]

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

