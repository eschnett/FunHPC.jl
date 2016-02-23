module Memoizeds

# Memoized data for the current iteration

using Comm, Par, Refs
using Cells, Defs, Domains, Grids, Norms

import Base.wait

export Memoized
export wait
export rk2
export info_output, file_output

immutable Memoized
    n::Int
    state::Ref{Domain}
    rhs::Ref{Domain}
    error::Ref{Domain}
    errorNorm::Ref{Norm}
    
    function Memoized(n::Int, state::Ref{Domain})
        rhs = @par Domain Domains.rhs(get(state))
        error = @par Domain Domains.error(get(state))
        errorNorm = @par Norm Domains.norm(get(error))
        new(n, state, rhs, error, errorNorm)
    end
end

function wait(m::Memoized)
    wait(get(m.state))
    wait(get(m.rhs))
    wait(get(m.error))
    wait(m.errorNorm)
end

# RK2
function rk2(m::Memoized)
    s0 = m.state
    r0 = m.rhs
    # Step 1
    s1 = @par Domain Domains.axpy(0.5 * Defs.dt(), get(r0), get(s0))
    r1 = @par Domain Domains.rhs(get(s1))
    # Step 2
    @par Domain Domains.axpy(Defs.dt(), get(r1), get(s0))
end

# Output
# TODO: futurize
function do_info_output(io::IO, m::Memoized)
    @assert myproc() == 1
    s = get(m.state)
    en = get(m.errorNorm)
    cell_size = norm(Cell()).count
    ncells = en.count / cell_size
    println(io, "n=", m.n, " t=", s.t, " ",
            "ncells: ", ncells, " L2-norm[error]: ", norm2(en))
end

function info_output(io::IO, m::Memoized;
                     is_first::Bool=false, was_last::Bool=false)
    if Defs.do_this_time(m.n, Defs.info_every,
                         is_first=is_first, was_last=was_last)
        do_info_output(io, m)
    end
end

# TODO: futurize
function do_file_output(io::IO, m::Memoized)
    @assert myproc() == 1
    s = get(m.state)
    r = get(m.rhs)
    en = get(m.errorNorm)
    cell_size = norm(Cell()).count
    ncells = en.count / cell_size
    print(io, "State: ", s)
    print(io, "RHS: ", r)
    println(io, "ncells: ", ncells, " L2-norm[error]: ", norm2(en))
    println(io)
end

function file_output(io::IO, m::Memoized;
                     is_first::Bool=false, was_last::Bool=false)
    if Defs.do_this_time(m.n, Defs.file_every,
                         is_first=is_first, was_last=was_last)
        do_file_output(io, m)
    end
end

end
