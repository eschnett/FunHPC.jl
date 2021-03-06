module Comm

using Funs, MPI

## import Base.LPROC, Base.PGRP

export ProcID, procid
# export myproc, procs, nprocs
export run_main
export rexec   # @rexec
export rexec_everywhere   # @rexec_everywhere

typealias ProcID Int

const OPTIMIZE_SELF_COMMUNICATION = false   #TODO true
const USE_MPI_MANAGER = false



type CommInfo
    was_initialized::Bool
    comm::MPI.Comm
    rank::Int
    size::Int
    manager::MPIManager
    CommInfo() = new()
end
const comminfo = CommInfo()

function init()
    comminfo.was_initialized = MPI.Initialized()
    if !comminfo.was_initialized
        MPI.Init()
    end
    # comminfo.comm = MPI.Comm_dup(MPI.COMM_WORLD)
    comminfo.comm = MPI.COMM_WORLD
    comminfo.rank = MPI.Comm_rank(comminfo.comm)
    comminfo.size = MPI.Comm_size(comminfo.comm)
    if USE_MPI_MANAGER
        # This call returns only on the root process
        @assert comminfo.comm == MPI.COMM_WORLD
        comminfo.manager = MPI.start(MPI_TRANSPORT_ALL)
    else
        ## # Override some Base settings to describe our multi-process setup
        ## LPROC.id = myproc()
        ## PGRP.workers = collect(procs())
    end
end

function finalize()
    if USE_MPI_MANAGER
        if !comminfo.was_initialized && !MPI.Finalized()
            @mpi_do comminfo.manager MPI.Finalize()
        end
    else
        ## # Undo override above to prevent errors during shutdown
        ## LPROC.id = 1
        ## PGRP.workers = []
        if !comminfo.was_initialized && !MPI.Finalized()
            MPI.Finalize()
        end
    end
end

myproc() = comminfo.rank+1
nprocs() = comminfo.size
procs() = 1:nprocs()



type CommState
    use_recv_loop::Bool
    stop_sending::Bool
    stop_receiving::Bool
    CommState() = new()
end
const commstate = CommState()

const TAG = 0
const META_TAG = 1

# Prevent unnecessary specialization
immutable Item
    item::Any
end
(item::Item)() = item.item()

# TODO: Use TestSome
function send_item(p::Int, t::Int, item::Item)
    @assert commstate.use_recv_loop
    req = MPI.isend(item, p-1, t, comminfo.comm)
    while t==META_TAG || !commstate.stop_sending
        flag, status = MPI.Test!(req)
        flag && return
        yield()
    end
    # MPI.cancel(req)
    nothing
end

function recv_item(p::Int, t::Int)
    @assert commstate.use_recv_loop
    while t==META_TAG || !commstate.stop_receiving
        flag, item, status =
            MPI.irecv(p==0 ? MPI.ANY_SOURCE : p-1, t, comminfo.comm)
        flag && return item::Item
        yield()
    end
    Item(nothing)
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
        @async send_item(c, META_TAG, Item(nothing))
    end
    # Wait for termination confirmation from children
    @sync for c in cmin:cmax
        @async recv_item(c, META_TAG)
    end
    # Send termination confirmation to parent
    @sync for p in pmin:pmax
        @async send_item(p, META_TAG, Item(nothing))
    end
    # Stage 2: Stop receiving
    # Wait for second termination message from parent
    @sync for p in pmin:pmax
        @async recv_item(p, META_TAG)
    end
    commstate.stop_receiving = true
    # Send second termination message to children
    @sync for c in cmin:cmax
        @async send_item(c, META_TAG, Item(nothing))
    end
end



const main_running = Ref{Bool}(false)
function run_main(main; run_main_everywhere::Bool=false)
    @assert !main_running[]
    main_running[] = true
    init()
    @assert !USE_MPI_MANAGER
    commstate.use_recv_loop = !(OPTIMIZE_SELF_COMMUNICATION && nprocs()==1)
    r = nothing
    @sync begin
        if commstate.use_recv_loop
            commstate.stop_sending = false
            commstate.stop_receiving = false
            @async recv_loop()
        end
        if run_main_everywhere || myproc()==1
            r = main()
        end
        if commstate.use_recv_loop
            terminate()
        end
    end
    finalize()
    @assert main_running[]
    main_running[] = false
    r
end

function recv_loop()
    @assert commstate.use_recv_loop
    try
        while !commstate.stop_receiving
            run_task(recv_item(0, TAG))
        end
    catch ex
        info(ex)
    end
end

function run_task(item::Item)
    if !commstate.stop_sending
        @schedule item()
    end
    nothing
end



rexec(f, p::Int) = rexec(Item(f), p)
function rexec(item::Item, p::Int)
    if OPTIMIZE_SELF_COMMUNICATION && p == myproc()
        run_task(item)
    else
        @schedule send_item(p, TAG, item)
    end
    nothing
end

function _rexec_tree(item::Item)
    pmin = 2*myproc()
    pmax = min(2*myproc()+1, nprocs())
    for p in pmin:pmax
        rexec(p) do
            _rexec_tree(item)
        end
    end
    item()
    nothing
end
rexec_everywhere(f) = rexec_everywhere(Item(f))
function rexec_everywhere(item::Item)
    rexec(1) do
        _rexec_tree(item)
    end
    nothing
end

# macro rexec(p, expr)
#     :(rexec(()->$(esc(expr)), $(esc(p))))
# end
# 
# macro rexec_everywhere(expr)
#     :(rexec_everywhere(()->$(esc(expr))))
# end

end
