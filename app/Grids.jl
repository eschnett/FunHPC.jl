module Grids

# Each grid lives on a process

using Foldable, Functor, StencilFunctor
using Cells, Defs, Norms
using Comm

import Base.show
import Norms.norm
import Cells.axpy, Cells.initial, Cells.error, Cells.rhs

export Grid
export getBoundary, axpy, norm, initial, error, rhs

immutable Grid
    imin::Int                   # spatial indices
    imax::Int
    cells::Vector{Cell}
    function Grid(imin, imax, cells)
        # println("Running on process $(Comm.comminfo.rank)")
        @assert imax>imin
        new(imin, imax, cells)
    end
end

function show(io::IO, g::Grid)
    println(io, "    grid: imin=", g.imin, " imax=", g.imax)
    for (i,c) in enumerate(g.cells)
        println(io, "        i=", i+g.imin-1, " ", c)
    end
end

imax(imin::Int) = min(imin + Defs.ncells_per_grid - 1, Defs.ncells())
x(i::Int) = Defs.xmin + (float(i) - 0.5) * Defs.dx()

getBoundary(g::Grid, face::Bool) = face ? g.cells[end] : g.cells[1]

# Linear combination
axpy(a::Float64, x::Grid, y::Grid) =
    Grid(y.imin, y.imax,
         fmap(R=Cell, (x,y) -> Cells.axpy(a,x,y), x.cells, y.cells))

# Norm
norm(g::Grid) = freduce((n,c) -> n+norm(c), Norm(), g.cells)

# Initial condition
initial(t::Float64, imin::Int) =
    Grid(imin, imax(imin), [Cells.initial(t, x(i)) for i in imin:imax(imin)])

# Error
error(g::Grid, t::Float64) =
    Grid(g.imin, g.imax, fmap(R=Cell, c -> Cells.error(c,t), g.cells))

# RHS
rhs(g::Grid, bm::Cell, bp::Cell) =
    Grid(g.imin, g.imax,
         stencil_fmap(R=Cell, Cells.rhs, (c,f)->c, g.cells, bm, bp))

end
