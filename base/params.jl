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
	"number of exits"
	n_exits			:: Int		= 10
	"number of starting positions"
	n_entries		:: Int		= 3
	"where to start connecting cities to exits"
	exit_dist		:: Float64	= 0.5
	"where to stop connecting cities to entries"
	entry_dist		:: Float64	= 0.1
	"quality of entries"
	qual_entry		:: Float64	= 0.0
	"resources at entries"
	res_entry		:: Float64	= 0.0
	"quality of exits"
	qual_exit		:: Float64	= 1
	"resources at exits"
	res_exit		:: Float64	= 1

	# scale >= 1.0 required, otherwise path finding breaks
	"how friction scales with distance"
	dist_scale		:: VF		= [1.0, 10.0]
	"stochastic range of friction"
	frict_range		:: Float64	= 0.5

	"number of contacts when entering"
	n_ini_contacts	:: Int		= 10
	"amount of capital when entering"
	ini_capital 	:: Float64 	= 2000.0
	"prob. to know a target when entering"
	p_know_target	:: Float64	= 0.0

	"expected resources at newly found city"
	res_exp			:: Float64	= 0.5
	"expected quality at newly found city"
	qual_exp		:: Float64	= 0.5
	"expected friction for newly found link"
	frict_exp		:: VF		= [1.25, 12.5]
	"prob. to find links when exploring"
	p_find_links	:: Float64	= 0.5
	"trust in detected friction for discovered links"
	trust_found_links :: Float64 = 0.5
	"prob. to find destinations of found links"
	p_find_dests	:: Float64	= 0.3
	"trust in information collected while travelling"
	trust_travelled	:: Float64	= 0.8
	"speed of exploration while staying"
	speed_expl_stay :: Float64	= 1.0
	"speed of exploration while moving"
	speed_expl_move :: Float64	= 1.0

	"resource costs of staying"
	costs_stay		:: Float64	= 1.0
	"benefit of resource uptake"
	ben_resources	:: Float64	= 5.0
	"resource costs of moving"
	costs_move		:: Float64	= 2.0

	"elasticity of traffic counter"
	ret_traffic		:: Float64	= 0.8
	"effect of traffic on current quality"
	weight_traffic	:: Float64	= 0.001

	"effect of proximity to exit on perceived quality"
	qual_weight_x	:: Float64	= 0.5
	"effect of resources on perceived quality"
	qual_weight_res	:: Float64 = 0.1
	"effect of friction on perceived quality"
	qual_weight_frict :: Float64 = 0.1
	"whether to take into account quality while planning a path"
	path_use_quality:: Bool		= true
	"effect of friction on path costs"
	path_weight_frict :: Float64 = 1.0

	"prob. to add an agent to contacts"
	p_keep_contact 	:: Float64 	= 0.1
	"prob. to lose contact"
	p_drop_contact	:: Float64	= 0.0
	"prob. to exchange info locally"
	p_info_mingle	:: Float64	= 0.1
	"prob. to exchange info with contacts"
	p_info_contacts	:: Float64	= 0.1
	"prob. to transfer info item"
	p_transfer_info	:: Float64	= 0.1
	"maximum number of contacts"
	n_contacts_max	:: Int		= 50
	"learning speed of arrived agents"
	arr_learn		:: Float64	= 0.0
	"change doubt into belief"
	convince		:: Float64	= 0.5
	"change belief into other belief"
	convert			:: Float64	= 0.1
	"change belief into doubt"
	confuse			:: Float64	= 0.3
	"stochastic error when transmitting information"
	error			:: Float64 	= 0.1
	"weight of opinion of arrived agents"
	weight_arr		:: Float64	= 1.0
end

