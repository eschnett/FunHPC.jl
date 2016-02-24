module Cells

# A cell -- a container holding data, no intelligence here

using Defs, Norms

import Base.show
import Norms.norm

export Cell
export axpy, norm, analytic, initial, boundary, error, rhs

immutable Cell
    x::Float64
    u::Float64
    rho::Float64
    v::Float64
end
Cell() = Cell(0.0, 0.0, 0.0, 0.0)

show(io::IO, c::Cell) =
    print(io, "cell: x=", c.x, " u=", c.u, " rho=", c.rho, " v=", c.v)

# Linear combination
axpy(a::Float64, x::Cell, y::Cell) =
    Cell(a*x.x + y.x, a*x.u + y.u, a*x.rho + y.rho, a*x.v + y.v)

# Norm
norm(c::Cell) = norm(c.u) + norm(c.rho) + norm(c.v)

# Analytic solution
analytic(t::Float64, x::Float64) =
    Cell(x,
         sin(2pi * t) * sin(2pi * x),
         2pi * cos(2pi * t) * sin(2pi * x),
         2pi * sin(2pi * t) * cos(2pi * x))

# Initial condition
initial(t::Float64, x::Float64) = analytic(t, x)

# Boundary condition
boundary(t::Float64, x::Float64) = analytic(t, x)

# Error
error(c::Cell, t::Float64) = axpy(-1.0, analytic(t, c.x), c)

# RHS
rhs(c::Cell, cm::Cell, cp::Cell) =
    Cell(0.0,                   # dx/dt
         c.rho,
         (cp.v - cm.v) / (2 * Defs.dx()),
         (cp.rho - cm.rho) / (2 * Defs.dx()))

end
