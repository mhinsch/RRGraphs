# this package provides some nice convenience syntax 
# for parameters
using Parameters

@with_kw struct Params
	# the macro will move the default values into the constructor
	rand_seed		:: Int		= 113

	n_cities		:: Int		= 100
	link_thresh		:: Float64	= 0.2

	n_start_pos 	:: Int 		= 3
	rate_dep	 	:: Float64	= 20
	n_exits			:: Int		= 5
	n_entries		:: Int		= 3

	dist_scale					= [1.0, 10.0]

	n_ini_contacts	:: Int		= 10
	ini_capital 	:: Float64 	= 2000.0
	p_know_target	:: Float64	= 0.0

	res_exp			:: Float64	= 0.5
	qual_exp		:: Float64	= 0.5
	frict_exp		:: Float64	= 0.5
	move_learn		:: Float64	= 0.3
	p_find_links	:: Float64	= 0.5
	trust_found_links :: Float64 = 0.5
	p_find_dests	:: Float64	= 0.3
	trust_travelled	:: Float64	= 0.8

	costs_stay		:: Float64	= 1.0
	ben_resources	:: Float64	= 5.0
	costs_move		:: Float64	= 2.0

	qual_weight_x	:: Float64	= 0.5
	qual_weight_trust :: Float64 = 0.1
	qual_weight_frict :: Float64 = 0.01

	p_keep_contact 	:: Float64 	= 0.5
	p_info_mingle	:: Float64	= 0.3
	p_info_contacts	:: Float64	= 0.2
	p_transfer_info	:: Float64	= 0.3

end

