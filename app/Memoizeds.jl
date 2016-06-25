module Memoizeds

# Memoized data for the current iteration

using Comm, FunRefs, Par
using Cells, Defs, Domains, Grids, Norms

import Base.wait

export Memoized
export wait
export rk2
export info_output, file_output

immutable Memoized
    n::Int
    state::FunRef{Domain}
    rhs::FunRef{Domain}
    error::FunRef{Domain}
    errorNorm::FunRef{Norm}
    
    function Memoized(n::Int, state::FunRef{Domain})
        rhs = par(R=Domain) do; Domains.rhs(state[]) end
        error = par(R=Domain) do; Domains.error(state[]) end
        errorNorm = par(R=Norm) do; Domains.norm(error[]) end
        new(n, state, rhs, error, errorNorm)
    end
end

function wait(m::Memoized)
    wait(m.state[])
    wait(m.rhs[])
    wait(m.error[])
    wait(m.errorNorm)
end

# RK2
function rk2(m::Memoized)
    s0 = m.state
    r0 = m.rhs
    # Step 1
    s1 = par(R=Domain) do; Domains.axpy(0.5 * Defs.dt(), r0[], s0[]) end
    r1 = par(R=Domain) do; Domains.rhs(s1[]) end
    # Step 2
    par(R=Domain) do; Domains.axpy(Defs.dt(), r1[], s0[]) end
end

# Output
# TODO: futurize
function do_info_output(io::IO, m::Memoized)
    @assert Comm.myproc() == 1
    s = m.state[]
    en = m.errorNorm[]
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
    @assert Comm.myproc() == 1
    s = m.state[]
    r = m.rhs[]
    en = m.errorNorm[]
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
