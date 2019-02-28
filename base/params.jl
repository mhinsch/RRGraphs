# this package provides some nice convenience syntax 
# for parameters
using Parameters

const VF = Vector{Float64}

"Simulation parameters"
@with_kw struct Params
	# the macro will move the default values into the constructor
	"rng seed for the simulation"
	rand_seed_sim	:: Int		= 113
	"rng seed for world creation"
	rand_seed_world	:: Int		= 123

	"number of cities"
	n_cities		:: Int		= 300
	"maximum distance for link generation"
	link_thresh		:: Float64	= 0.1

	"number of departures per time step"
	rate_dep	 	:: Float64	= 20
	n_exits			:: Int		= 10
	"number of starting positions"
	n_entries		:: Int		= 3
	exit_dist		:: Float64	= 0.5
	entry_dist		:: Float64	= 0.1
	qual_entry		:: Float64	= 0.0
	res_entry		:: Float64	= 0.0
	qual_exit		:: Float64	= 1
	res_exit		:: Float64	= 1

	# scale >= 1.0 required, otherwise path finding breaks
	dist_scale		:: VF		= [1.0, 10.0]
	# stochastic range of friction
	frict_range		:: Float64	= 0.5

	n_ini_contacts	:: Int		= 10
	ini_capital 	:: Float64 	= 2000.0
	p_know_target	:: Float64	= 0.0

	res_exp			:: Float64	= 0.5
	qual_exp		:: Float64	= 0.5
	frict_exp		:: VF		= [1.25, 12.5]
	p_find_links	:: Float64	= 0.5
	trust_found_links :: Float64 = 0.5
	p_find_dests	:: Float64	= 0.3
	trust_travelled	:: Float64	= 0.8
	speed_expl_stay :: Float64	= 1.0
	speed_expl_move :: Float64	= 1.0

	costs_stay		:: Float64	= 1.0
	ben_resources	:: Float64	= 5.0
	costs_move		:: Float64	= 2.0

	qual_weight_x	:: Float64	= 0.5
	qual_weight_res	:: Float64 = 0.1
	qual_weight_frict :: Float64 = 0.1

	p_keep_contact 	:: Float64 	= 0.1
	p_info_mingle	:: Float64	= 0.1
	p_info_contacts	:: Float64	= 0.1
	p_transfer_info	:: Float64	= 0.1
	n_contacts_max	:: Int		= 50
	arr_learn		:: Float64	= 0.0
	"change doubt into belief"
	convince		:: Float64	= 0.5
	"change belief into other belief"
	convert			:: Float64	= 0.1
	"change belief into doubt"
	confuse			:: Float64	= 0.3
end

