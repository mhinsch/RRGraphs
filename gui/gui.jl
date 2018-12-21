using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer 

import SimpleDirectMediaLayer.LoadBMP

SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 16)
SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 16)

SDL2.init()

const panel_size = 800
const win_size = 2 * panel_size

win = SDL2.CreateWindow("Routes & Rumours", Int32(0), Int32(0), Int32(win_size), Int32(win_size), 
    UInt32(SDL2.WINDOW_SHOWN))
SDL2.SetWindowResizable(win,false)

surface = SDL2.GetWindowSurface(win)

renderer = SDL2.CreateRenderer(win, Int32(-1),
    UInt32(SDL2.RENDERER_ACCELERATED))


bkg = SDL2.Color(200, 200, 200, 255)

texture_tl = SDL2.CreateTexture(renderer, SDL2.PIXELFORMAT_ARGB8888, Int32(SDL2.TEXTUREACCESS_STREAMING), Int32(panel_size), Int32(panel_size))
texture_tr = SDL2.CreateTexture(renderer, SDL2.PIXELFORMAT_ARGB8888, Int32(SDL2.TEXTUREACCESS_STREAMING), Int32(panel_size), Int32(panel_size))
texture_bl = SDL2.CreateTexture(renderer, SDL2.PIXELFORMAT_ARGB8888, Int32(SDL2.TEXTUREACCESS_STREAMING), Int32(panel_size), Int32(panel_size))

pixels_bg = Vector{UInt32}(undef, panel_size*panel_size)
pixels = Vector{UInt32}(undef, panel_size*panel_size)

push!(LOAD_PATH, pwd())
include("../base/world.jl")
include("../base/init.jl")
include("../base/simulation.jl")
include("../base/draw.jl")
include("../base/params.jl")

using Random

# const for performance reasons
const parameters = Params()
Random.seed!(parameters.rand_seed)


world = create_world(parameters)
model = Model(world, Agent[], Agent[])

# int(n :: Float64) = floor(Int, n)

count = 1

fill!(pixels_bg, 0)
draw_bg!(Canvas(pixels_bg, panel_size), model)
rect_tl = SDL2.Rect(0, 0, panel_size, panel_size)
rect_tr = SDL2.Rect(panel_size, 0, panel_size, panel_size)
rect_bl = SDL2.Rect(0, panel_size, panel_size, panel_size)

while true
	println(count, " ", length(model.people))
	count += 1

	ev = SDL2.event()
	
	if typeof(ev) <: SDL2.KeyboardEvent #|| typeof(ev) <: SDL2.QuitEvent
		break;
	end

	for i in 1:1
		step_simulation!(model, parameters)
	end

	canvas = Canvas(pixels, panel_size)

	copyto!(pixels, pixels_bg)
	draw_people!(canvas, model)
	SDL2.UpdateTexture(texture_tl, C_NULL, pixels, Int32(panel_size * 4))

	fill!(pixels, 0)
	draw_rand_knowledge!(canvas, model)
	SDL2.UpdateTexture(texture_tr, C_NULL, pixels, Int32(panel_size * 4))

	if count % 10 == 0
		fill!(pixels, 0)
		draw_visitors!(canvas, model)
		SDL2.UpdateTexture(texture_bl, C_NULL, pixels, Int32(panel_size * 4))
	end

	SDL2.RenderClear(renderer)
	SDL2.RenderCopy(renderer, texture_tl, C_NULL, pointer_from_objref(rect_tl)) 
	SDL2.RenderCopy(renderer, texture_tr, C_NULL, pointer_from_objref(rect_tr))
	SDL2.RenderCopy(renderer, texture_bl, C_NULL, pointer_from_objref(rect_bl))

    SDL2.RenderPresent(renderer)
    sleep(0.001)
end
SDL2.Quit()
