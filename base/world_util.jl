
struct Pos
	x :: Float64
	y :: Float64
end

const Nowhere = Pos(-1.0, -1.0)


distance(p1 :: Pos, p2 :: Pos) = Util.distance(p1.x, p1.y, p2.x, p2.y)


struct Trusted{T}
	value :: T
	trust :: Float64

	function Trusted{T}(v :: T, t :: Float64) where {T}
		@assert 0.0 < t < 1.0
		new(v, t)
	end
end

function Trusted{T}(v :: T) where {T}
	Trusted{T}(v, eps(0.0))
end


const TrustedF = Trusted{Float64}


discounted(t :: Trusted{T}) where {T} = t.value * t.trust


update(t :: TrustedF, val, speed) = average(t, TrustedF(val, 1.0-eps(1.0)), speed)


average(val :: TrustedF, target :: TrustedF, weight = 0.5) =
	TrustedF(val.value * (1.0-weight) + target.value * weight, 
		val.trust * (1.0-weight) + target.trust * weight)

