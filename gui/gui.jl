using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer 

import SimpleDirectMediaLayer.LoadBMP

SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 16)
SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 16)

SDL2.init()

const wsize = 1025

win = SDL2.CreateWindow("Hello World!", Int32(0), Int32(0), Int32(wsize), Int32(wsize), 
    UInt32(SDL2.WINDOW_SHOWN))
SDL2.SetWindowResizable(win,false)

surface = SDL2.GetWindowSurface(win)

renderer = SDL2.CreateRenderer(win, Int32(-1),
    UInt32(SDL2.RENDERER_ACCELERATED))

import Base.unsafe_convert
unsafe_convert(::Type{Ptr{SDL2.RWops}}, s::String) = SDL2.RWFromFile(s, "rb")

bkg = SDL2.Color(200, 200, 200, 255)

texture = SDL2.CreateTexture(renderer, SDL2.PIXELFORMAT_ARGB8888, Int32(SDL2.TEXTUREACCESS_STREAMING), Int32(wsize), Int32(wsize))
pixels = Vector{UInt32}(undef, wsize*wsize)

push!(LOAD_PATH, "/home/martin/Science/southampton/src/rumours/")
include("../base/world.jl")
include("../base/init.jl")
include("../base/simulation.jl")
include("../base/draw.jl")
include("../base/params.jl")

using Random

# const for performance reasons
const parameters = Params(xsize = wsize, ysize = wsize)
Random.seed!(parameters.rand_seed)


world = create_world(parameters)
model = Model(world, Agent[], Agent[])

# int(n :: Float64) = floor(Int, n)

count = 1

while(true)
	println(count, " ", length(model.people))
	count += 1

	ev = SDL2.event()
	
	if typeof(ev) <: SDL2.KeyboardEvent || typeof(ev) <: SDL2.QuitEvent
		break;
	end

	for i in 1:5
		step_simulation!(model, parameters)
	end

	draw!(pixels, model)

	SDL2.UpdateTexture(texture, C_NULL, pixels, Int32(wsize * 4))
	SDL2.RenderClear(renderer)
	SDL2.RenderCopy(renderer, texture, C_NULL, C_NULL)

    SDL2.RenderPresent(renderer)
    sleep(0.001)
end
SDL2.Quit()
