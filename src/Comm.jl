module Comm

using Funs, MPI

import Base.LPROC, Base.PGRP

export ProcID, procid
export myproc, procs, nprocs
export run_main
export rexec, @rexec
export rexec_everywhere, @rexec_everywhere

typealias ProcID Int

const OPTIMIZE_SELF_COMMUNICATION = true



type CommInfo
    initialized::Bool
    comm::MPI.Comm
    rank::Int
    size::Int
    CommInfo() = new()
end
const comminfo = CommInfo()

function init()
    comminfo.initialized = MPI.Initialized()
    if !comminfo.initialized
        MPI.Init()
    end
    comminfo.comm = MPI.Comm_dup(MPI.COMM_WORLD)
    comminfo.rank = MPI.Comm_rank(comminfo.comm)
    comminfo.size = MPI.Comm_size(comminfo.comm)
    # Override some Base settings to describe our multi-process setup
    LPROC.id = myproc()
    PGRP.workers = collect(procs())
end

function finalize()
    # Undo override above to prevent errors during shutdown
    LPROC.id = 1
    PGRP.workers = []
    MPI.Comm_free(comminfo.comm)
    if comminfo.initialized && !MPI.Finalized()
        MPI.Finalize()
    end
end

myproc() = comminfo.rank+1
nprocs() = comminfo.size
procs() = 1:nprocs()



type CommState
    stop_sending::Bool
    stop_receiving::Bool
    use_recv_loop::Bool
    CommState() = new(false, false)
end
const commstate = CommState()

const TAG = 0
const META_TAG = 1

# TODO: Use TestSome
function send_item(p::Integer, t::Integer, item)
    @assert commstate.use_recv_loop
    req = MPI.isend(item, p-1, t, comminfo.com)
    while t==META_TAG || !commstate.stop_sending
        flag, status = MPI.Test!(req)
        if flag return end
        yield()
    end
    # MPI.cancel(req)
end

function recv_item(p::Integer, t::Integer)
    @assert commstate.use_recv_loop
    while t==META_TAG || !commstate.stop_receiving
        flag, item, status = MPI.irecv(p==0 ? MPI.ANY_SOURCE : p-1, t, comminfo.com)
        if flag return item end
        yield()
    end
end

function terminate()
    # TODO: Use MPI.Ibarrier
    @assert commstate.use_recv_loop
    # Determine parents and children for a binary tree
    pmax = div(myproc(), 2)
    pmin = max(pmax, 1)
    cmin = 2*myproc()
    cmax = min(2*myproc()+1, nprocs())
    # Stage 1: Stop sending
    # Wait for termination message from parent
    @sync for p in pmin:pmax
        @async recv_item(p, META_TAG)
    end
    # Stop sending
    commstate.stop_sending = true
    # Send termination message to children
    @sync for c in cmin:cmax
        @async send_item(c, META_TAG, nothing)
    end
    # Wait for termination confirmation from children
    @sync for c in cmin:cmax
        @async recv_item(c, META_TAG)
    end
    # Send termination confirmation to parent
    @sync for p in pmin:pmax
        @async send_item(p, META_TAG, nothing)
    end
    # Stage 2: Stop receiving
    # Wait for second termination message from parent
    @sync for p in pmin:pmax
        @async recv_item(p, META_TAG)
    end
    commstate.stop_receiving = true
    # Send second termination message to children
    @sync for c in cmin:cmax
        @async send_item(c, META_TAG, nothing)
    end
end



function run_main(main::Callable; run_main_everywhere::Bool=false)
    init()
    commstate.use_recv_loop = !(OPTIMIZE_SELF_COMMUNICATION && nprocs()==1)
    r = nothing
    @sync begin
        if commstate.use_recv_loop
            @async recv_loop()
        end
        if run_main_everywhere || myproc()==1
            r = call(main)
        end
        if commstate.use_recv_loop
            terminate()
        end
    end
    finalize()
    r
end

function recv_loop()
    @assert commstate.use_recv_loop
    while !STOP_RECEIVING
        run_task(recv_item(0, TAG))
    end
end

function run_task(item)
    if !commstate.stop_sending
        # (f::Callable, args...) = item
        @schedule call(item...)
    end
end



# TODO: Support sending arbitrary expressions, not just function calls
# TODO: Use a stagedfunction for this

# function rexec(p::Integer, f::Callable, args...)
#     item = tuple(f, args...)
#     if OPTIMIZE_SELF_COMMUNICATION && p == myproc()
#         run_task(item)
#     else
#         @schedule send_item(p, TAG, item)
#     end
# end
rexec(f::Callable, p::Integer) = rexec(p, f)
function rexec(p::Integer, f::Callable)
    item = tuple(f)
    if OPTIMIZE_SELF_COMMUNICATION && p == myproc()
        run_task(item)
    else
        @schedule send_item(p, TAG, item)
    end
end
function rexec(p::Integer, f::Callable, arg1)
    item = tuple(f, arg1)
    if OPTIMIZE_SELF_COMMUNICATION && p == myproc()
        run_task(item)
    else
        @schedule send_item(p, TAG, item)
    end
end
function rexec(p::Integer, f::Callable, arg1, arg2)
    item = tuple(f, arg1, arg2)
    if OPTIMIZE_SELF_COMMUNICATION && p == myproc()
        run_task(item)
    else
        @schedule send_item(p, TAG, item)
    end
end
function rexec(p::Integer, f::Callable, arg1, arg2, arg3)
    item = tuple(f, arg1, arg2, arg3)
    if OPTIMIZE_SELF_COMMUNICATION && p == myproc()
        run_task(item)
    else
        @schedule send_item(p, TAG, item)
    end
end
function rexec(p::Integer, f::Callable, arg1, arg2, arg3, arg4, args...)
    item = tuple(f, arg1, arg2, arg3, arg4, args...)
    if OPTIMIZE_SELF_COMMUNICATION && p == myproc()
        run_task(item)
    else
        @schedule send_item(p, TAG, item)
    end
end

function _rexec_tree(item)
    pmin = 2*myproc()
    pmax = min(2*myproc()+1, nprocs())
    for p in pmin:pmax
        rexec(p, _rexec_tree, item)
    end
    # (f::Callable, args...) = item
    call(item...)
end
function rexec_everywhere(f::Callable, args...)
    item = tuple(f, args...)
    rexec(1, _rexec_tree, item)
end

macro rexec(p, expr)
    esc(Base.localize_vars(:(rexec($p, ()->$expr)), false))
end

macro rexec_everywhere(expr)
    esc(Base.localize_vars(:(rexec_everywhere(()->$expr)), false))
end

end
