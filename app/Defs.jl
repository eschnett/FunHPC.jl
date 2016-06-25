module Defs

using Comm

# Global definitions, aka parameter file

const run_type = :debug     # :debug, :benchmark, :production

const ncells_per_grid = 10

const xmin = 0.0
const xmax = 1.0
const cfl = 0.5
const tmin = 0.0
const tmax = 1.0

const wait_every = 0

if run_type == :debug
    const rho = 1               # resolution scale
    const nsteps = -1
    const info_every = 10
    const file_every = 0
elseif run_type == :benchmark
    const rho = 100             # resolution scale
    const nsteps = 10
    const info_every = 0
    const file_every = -1
elseif run_type == :production
    @assert false
else
    @assert false
end

ncells() = (rho * ncells_per_grid * Comm.nprocs())::Int
dx() = ((xmax - xmin) / ncells())::Float64
dt() = (cfl * dx())::Float64

function do_this_time(iteration::Integer, do_every::Integer;
                      is_first::Bool=false, was_last::Bool=false)
    if do_every < 0 return false end
    if is_first return true end
    should_output = do_every > 0 && iteration % do_every == 0
    return should_output != was_last
end

end
