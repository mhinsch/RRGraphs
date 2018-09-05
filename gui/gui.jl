using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer 

import SimpleDirectMediaLayer.LoadBMP

SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 16)
SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 16)

SDL2.init()

const size = 2000

win = SDL2.CreateWindow("Hello World!", Int32(0), Int32(0), Int32(2000), Int32(2000), 
    UInt32(SDL2.WINDOW_SHOWN))
SDL2.SetWindowResizable(win,false)

surface = SDL2.GetWindowSurface(win)

renderer = SDL2.CreateRenderer(win, Int32(-1),
    UInt32(SDL2.RENDERER_ACCELERATED | SDL2.RENDERER_PRESENTVSYNC))

import Base.unsafe_convert
unsafe_convert(::Type{Ptr{SDL2.RWops}}, s::String) = SDL2.RWFromFile(s, "rb")

LoadBMP(src::String) = SDL2.LoadBMP_RW(src,Int32(1))

bkg = SDL2.Color(200, 200, 200, 255)

# Create text
#font = TTF_OpenFont(joinpath(@__DIR__,"FiraCode-Regular.ttf"), 30) 
#txt = "@BinDeps.install Dict([ (:glib, :libglib) ])"
#txt = "hi"
#text = TTF_RenderText_Blended(font, txt, SDL2.Color(20,20,20,255))
#tex = SDL2.CreateTextureFromSurface(renderer,text)

#fx,fy = Int[1], Int[1]
#TTF_SizeText(font, txt, pointer(fx), pointer(fy))
#fx,fy = fx[1],fy[1]

include("../GeoGraph/src/GeoGraph.jl")
using .GeoGraph

nodes, links = create_random_geo_graph(100, 0.2)
nodes = map(x->x.*size, nodes)

int(n :: Float64) = floor(Int, n)

while(true)
	ev = SDL2.event()
	
	if typeof(ev) <: SDL2.KeyboardEvent || typeof(ev) <: SDL2.QuitEvent
		break;
	end
	#x,y = Int[1], Int[1]
    #SDL2.GetMouseState(pointer(x), pointer(y))

    # Set render color to red ( background will be rendered in this color )
    SDL2.SetRenderDrawColor(renderer, 200, 200, 200, 255)
    SDL2.RenderClear(renderer)

    SDL2.SetRenderDrawColor(renderer, 20, 50, 105, 255)
	for l in links
		p1 = l[1]
		p2 = l[2]
    	SDL2.RenderDrawLine(renderer, int(nodes[p1][1]), int(nodes[p1][2]), int(nodes[p2][1]), int(nodes[p2][2]))
	end

    #rect = SDL2.Rect(1,1,200,200)
    #SDL2.RenderFillRect(renderer, pointer_from_objref(rect) )
    #SDL2.RenderCopy(renderer, tex, C_NULL, pointer_from_objref(SDL2.Rect(x[1],y[1],fx,fy)))

    SDL2.RenderPresent(renderer)
    sleep(0.001)
end
SDL2.Quit()
