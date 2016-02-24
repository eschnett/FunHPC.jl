module Domains

# The domain is distributed over multiple processes

using Comm, Par, Refs
using Foldable, Functor, StencilFunctor
using Cells, Defs, Grids, Norms

import Base.show, Base.wait
import Norms.norm
import Cells.axpy, Cells.initial, Cells.error, Cells.rhs

export Domain
export show, wait
export axpy, norm, initial, error, rhs

immutable Domain
    t::Float64
    grids::Vector{Ref{Grid}}
end

function show(io::IO, d::Domain)
    println(io, "domain: t=", d.t)
    for g in d.grids
        print(io, get_remote(g)) # TODO
    end
end

function wait(d::Domain)
    fmap(wait, d.grids)
end

# Linear combination
function axpy(a::Float64, x::Domain, y::Domain)
    function gaxpy(x::Ref{Grid}, y::Ref{Grid})
        @remote Grid y Grids.axpy(a, get_remote(x), get(y))
    end
    Domain(a * x.t + y.t, fmap(R=Ref{Grid}, gaxpy, x.grids, y.grids))
end

# Norm
function norm(d::Domain)
    function gnorm(g::Ref{Grid})
        @rpar Norm g Grids.norm(get(g))
    end
    freduce((n,g)->n+get(g), Norm(), fmap(R=Ref{Norm}, gnorm, d.grids))
end

# Initial condition
# (Also choose a domain decomposition)
function initial(t::Float64)
    is = 1:Defs.ncells_per_grid:Defs.ncells()
    function ginitial(i::Integer)
        @remote Grid chooseproc(i,is) Grids.initial(t,i)
    end
    Domain(t, Ref{Grid}[ginitial(i) for i in is])
end
function chooseproc(i::Integer, r::Range)
    p = div(i - first(r), step(r)) + 1
    mod1(p, nprocs())
end

# Error
function error(d::Domain)
    function gerror(g::Ref{Grid})
        @remote Grid g Grids.error(get(g), d.t)
    end
    Domain(d.t, fmap(R=Ref{Grid}, gerror, d.grids))
end

# RHS
function rhs(d::Domain)
    function grhs(g::Ref{Grid}, bm::Ref{Cell}, bp::Ref{Cell})
        @remote Grid g Grids.rhs(get(g), get_remote(bm), get_remote(bp))
    end
    function gbnd(g::Ref{Grid}, face::Bool)
        @remote Cell g Grids.getBoundary(get(g), face)
    end
    bm = @par Cell Cells.boundary(d.t, Defs.xmin - 0.5 * Defs.dx())
    bp = @par Cell Cells.boundary(d.t, Defs.xmax + 0.5 * Defs.dx())
    Domain(1.0,                 # dt/dt
           stencil_fmap(R=Ref{Grid}, grhs, gbnd, d.grids, bm, bp))
end

end
