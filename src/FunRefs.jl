module FunRefs

using Comm, Foldable, Functor, Funs, GIDs, Monad

import Base: show
import Base: eltype, getindex, setindex!, ==, isready, wait
import Base: serialize, deserialize
import Base: length, start, next, done, isempty

import GIDs: islocal

export FunRef
export proc, islocal
export set!, set_from_ref!   # reset!



immutable FunRefRemoteReady end
immutable FunRefRemoteUnready end

# TODO: Replace ready,cond by Maybe{Condition}

type FunRef{T}
    ready::Bool
    gid::GID                    # if ready
    obj::T                      # cache, if ready and local
    cond::Condition             # while not ready

    # Create unready
    function FunRef()
        ref = new(false)
        ref.cond = Condition()
        ref
    end
    # Create from local object
    function FunRef(obj::T)
        # gid = makegid(obj)
        gid = nullgid()
        ref = new(true, gid, obj)
        ref
    end
    # Create from ready remote reference
    function FunRef(::FunRefRemoteReady, gid::GID, prevgid::GID)
        @assert !isnull(gid) && !isnull(prevgid)
        ref = new(true, gid)
        finalizer(ref, finalize)
        if islocal(gid) ref.obj = getobj(gid) end
        take_ownership(ref, prevgid)
        ref
    end
    # Create from unready remote reference
    function FunRef(::FunRefRemoteUnready, prevgid::GID)
        @assert !isnull(prevgid)
        ref = new(false)
        ref.cond = Condition()
        wait_for_ref(ref, prevgid)
        ref
    end
end

FunRef{T}(obj::T) = FunRef{T}(obj)

# Do not free GIDs during garbage collection. Instead, put them on a to-free
# list, and have a worker thread periodically free the GIDs on this list.
global GIDLIST = GID[]
function mark_gid(gid::GID)
    global GIDLIST::Array{GID,1}
    push!(GIDLIST, gid)
end
function free_gids()
    global GIDLIST::Array{GID,1}
    gidlist = GID[]
    while true
        yield()
        gidlist, GIDLIST = GIDLIST, gidlist
        map(free, gidlist)
        empty!(gidlist)
    end
end
@schedule free_gids()

function finalize(ref::FunRef)
    # if !isready(ref) return end
    # if isnull(ref.gid) return end
    @assert isready(ref)
    @assert !isnull(ref.gid)
    # free(ref.gid)
    mark_gid(ref.gid)
end
function ensure_have_gid(ref::FunRef)
    if !isnull(ref.gid) return end
    ref.gid = makegid(ref.obj)
    finalizer(ref, finalize)
end
function take_ownership(ref::FunRef, prevgid::GID)
    @assert !isnull(ref.gid) && !isnull(prevgid)
    gid = ref.gid
    refgid = makegid(ref)
    rexec(gid.proc) do
        take_ownership2(gid, prevgid, refgid)
    end
end
function take_ownership2(gid::GID, prevgid::GID, refgid::GID)
    alloc(gid)
    free(prevgid)
    free(refgid)
end
function wait_for_ref(ref::FunRef, prevgid::GID)
    @assert !isnull(prevgid)
    refgid = makegid(ref)
    rexec(prevgid.proc) do
        wait_for_ref2(prevgid, refgid)
    end
end
function wait_for_ref2(prevgid::GID, refgid::GID)
    prev = getobj(prevgid)::FunRef
    wait(prev)
    ensure_have_gid(prev)
    rexec(refgid.proc) do
        wait_for_ref3(refgid, prev.gid, prevgid)
    end
end
function wait_for_ref3(refgid::GID, gid::GID, prevgid::GID)
    ref = getobj(refgid)::FunRef
    set!(ref, gid, prevgid)
end

function setindex!{T}(ref::FunRef{T}, obj)
    @assert !isready(ref)
    # gid = makegid(obj)
    gid = nullgid()
    ref.gid = gid
    ref.obj = obj
    ref.ready = true
    notify(ref.cond)
end
function set!{T}(ref::FunRef{T}, gid::GID, prevgid::GID)
    @assert !isready(ref)
    @assert !isnull(gid) && !isnull(prevgid)
    ref.gid = gid
    finalizer(ref, finalize)
    if islocal(gid) ref.obj = getobj(gid) end
    ref.ready = true
    notify(ref.cond)
    take_ownership(ref, prevgid)
end
# This could have a more generic signature
function set_from_ref!{T}(ref::FunRef{T}, other::FunRef{T})
    if islocal(other)
        ref[] = other[]
    else
        wait(other)
        othergid = makegid(other)
        set!(ref, other.gid, othergid)
    end
end
# Don't know how to unset ref.obj
# function reset!(ref::FunRef)
#     @assert isready(ref)
#     if islocal(ref.gid) ref.obj = nothing end
#     free(ref.gid)
#     ref.ready = false
#     ref.cond = Condition()
# end

function show(io::IO, ref::FunRef)
    if !isready(ref)
        print(io, "$(typeof(ref))($(ref.ready))")
    elseif !islocal(ref)
        print(io, "$(typeof(ref))($(ref.ready),$(ref.gid))")
    else
        print(io, "$(typeof(ref))($(ref.ready),$(ref.gid),$(ref.obj))")
    end
end

eltype{T}(ref::FunRef{T}) = T

function isready(ref::FunRef)
    ref.ready
end
function wait(ref::FunRef)
    if isready(ref) return end
    # Note: There must be no interruption between the "isready" and
    # the "wait"; in particular, there can be no I/O here.
    wait(ref.cond)
    # while !isready(ref)
    #     sleep(0.01)
    # end
end

function proc(ref::FunRef)
    wait(ref)
    if isnull(ref.gid) return Comm.myproc() end
    ref.gid.proc
end
function islocal(ref::FunRef)
    # proc(ref) == Comm.myproc()
    wait(ref)
    islocal(ref.gid)
end
function getindex{T}(ref::FunRef{T})
    wait(ref)
    @assert islocal(ref)
    ref.obj::T
end

# function =={T}(ref1::FunRef{T}, ref2::FunRef{T})
#     wait(ref1, ref2)
#     ref1.gid == ref2.gid
# end



function serialize{T}(s::AbstractSerializer, ref::FunRef{T})
    Base.serialize_type(s, FunRef{T})
    write(s.io, ref.ready)
    if ref.ready
        ensure_have_gid(ref)
        write(s.io, ref.gid)
        refgid = makegid(ref)
        write(s.io, refgid)
     else
        refgid = makegid(ref)
        write(s.io, refgid)
    end
end
function deserialize{T}(s::AbstractSerializer, ::Type{FunRef{T}})
    ready = read(s.io, Bool)
    if ready
        gid = read(s.io, GID)
        prevgid = read(s.io, GID)
        FunRef{T}(FunRefRemoteReady(), gid, prevgid)
    else
        prevgid = read(s.io, GID)
        FunRef{T}(FunRefRemoteUnready(), prevgid)
    end
end



length(ref::FunRef) = 1
start(ref::FunRef) = false
next(ref::FunRef, i) = ref[], true
done(ref::FunRef, i) = i
isempty(ref::FunRef) = false
getindex(ref::FunRef, i::Integer) = (@assert i==1; ref[])
setindex!(ref::FunRef, i::Integer, val) = (@assert i==1; ref[]=val)

end
