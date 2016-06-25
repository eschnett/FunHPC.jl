module Domains

# The domain is distributed over multiple processes

using Comm, FunRefs, Par
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
    grids::Vector{FunRef{Grid}}
end

function show(io::IO, d::Domain)
    println(io, "domain: t=", d.t)
    for g in d.grids
        print(io, get_local(g)) # TODO
    end
end

function wait(d::Domain)
    fmap(wait, d.grids)
end

# Linear combination
function axpy(a::Float64, x::Domain, y::Domain)
    function gaxpy(x::FunRef{Grid}, y::FunRef{Grid})
        remote(y, R=Grid) do
            Grids.axpy(a, get_local(x), y[])
        end
    end
    Domain(a * x.t + y.t, fmap(R=FunRef{Grid}, gaxpy, x.grids, y.grids))
end

# Norm
function norm(d::Domain)
    function gnorm(g::FunRef{Grid})
        rpar(g, R=Norm) do; Grids.norm(g[]) end
    end
    freduce((n,g)->n+g[], Norm(), fmap(R=FunRef{Norm}, gnorm, d.grids))
end

# Initial condition
# (Also choose a domain decomposition)
function initial(t::Float64)
    is = 1:Defs.ncells_per_grid:Defs.ncells()
    function ginitial(i::Integer)
        remote(chooseproc(i,is), R=Grid) do; Grids.initial(t,i) end
    end
    Domain(t, FunRef{Grid}[ginitial(i) for i in is])
end
function chooseproc(i::Integer, r::Range)
    p = div(i - first(r), step(r)) + 1
    mod1(p, Comm.nprocs())
end

# Error
function error(d::Domain)
    function gerror(g::FunRef{Grid})
        remote(g, R=Grid) do; Grids.error(g[], d.t) end
    end
    Domain(d.t, fmap(R=FunRef{Grid}, gerror, d.grids))
end

# RHS
function rhs(d::Domain)
    function grhs(g::FunRef{Grid}, bm::FunRef{Cell}, bp::FunRef{Cell})
        remote(g, R=Grid) do
            Grids.rhs(g[], get_local(bm), get_local(bp))
        end
    end
    function gbnd(g::FunRef{Grid}, face::Bool)
        remote(g, R=Cell) do; Grids.getBoundary(g[], face) end
    end
    bm = par(R=Cell) do; Cells.boundary(d.t, Defs.xmin - 0.5 * Defs.dx()) end
    bp = par(R=Cell) do; Cells.boundary(d.t, Defs.xmax + 0.5 * Defs.dx()) end
    Domain(1.0,                 # dt/dt
           stencil_fmap(R=FunRef{Grid}, grhs, gbnd, d.grids, bm, bp))
end

end
