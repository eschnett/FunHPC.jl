module Refs

using Comm, Foldable, Functor, Funs, GIDs, Monad

import Base.show
import Base.eltype, Base.get, Base.==, Base.wait
import Base.serialize, Base.deserialize
import Base.length, Base.start, Base.next, Base.done, Base.isempty
import Base.getindex

import GIDs.islocal

export Ref, ref
export set!, set_from_ref!                               # reset!
export eltype, get, getproc, islocal, isready, get, wait # ==
export length, start, next, done, isempty
export getindex



immutable RefRemoteReady end
immutable RefRemoteUnready end

# TODO: Replace ready,cond by Maybe{Condition}

type Ref{T}
    ready::Bool
    gid::GID                    # if ready
    obj::T                      # cache, if ready and local
    cond::Condition             # while not ready
    
    # Create unready
    function Ref()
        ref = new(false)
        ref.cond = Condition()
        ref
    end
    # Create from local object
    function Ref(obj)
        # gid = makegid(obj)
        gid = nullgid()
        ref = new(true, gid, obj)
        ref
    end
    # Create from ready remote reference
    function Ref(::RefRemoteReady, gid::GID, prevgid::GID)
        @assert !isnull(gid) && !isnull(prevgid)
        ref = new(true, gid)
        finalizer(ref, finalize)
        if islocal(gid) ref.obj = getobj(gid) end
        take_ownership(ref, prevgid)
        ref
    end
    # Create from unready remote reference
    function Ref(::RefRemoteUnready, prevgid::GID)
        @assert !isnull(prevgid)
        ref = new(false)
        ref.cond = Condition()
        wait_for_ref(ref, prevgid)
        ref
    end
end

ref{T}(obj::T) = Ref{T}(obj)

# Do not free GIDs during garbage collection. Instead, put them on a
# to-free list, and have a worker thread periodically free the GIDs on
# this list.
global GIDLIST = GID[]
function mark_gid(gid::GID)
    global GIDLIST::Array{GID,1}
    push!(GIDLIST, gid)
end
function free_gids()
    global GIDLIST::Array{GID,1}
    gidlist = GID[]
    while true
        sleep(0.1)
        gidlist, GIDLIST = GIDLIST, gidlist
        map(free, gidlist)
        empty!(gidlist)
    end
end
@schedule free_gids()

function finalize(ref::Ref)
    # if !isready(ref) return end
    # if isnull(ref.gid) return end
    @assert isready(ref)
    @assert !isnull(ref.gid)
    # free(ref.gid)
    mark_gid(ref.gid)
end
function ensure_have_gid(ref::Ref)
    if !isnull(ref.gid) return end
    ref.gid = makegid(ref.obj)
    finalizer(ref, finalize)
end
function take_ownership(ref::Ref, prevgid::GID)
    @assert !isnull(ref.gid) && !isnull(prevgid)
    gid = ref.gid
    refgid = makegid(ref)
    rexec(gid.proc, take_ownership2, gid, prevgid, refgid)
end
function take_ownership2(gid::GID, prevgid::GID, refgid::GID)
    alloc(gid)
    free(prevgid)
    free(refgid)
end
function wait_for_ref(ref::Ref, prevgid::GID)
    @assert !isnull(prevgid)
    refgid = makegid(ref)
    rexec(prevgid.proc, wait_for_ref2, prevgid, refgid)
end
function wait_for_ref2(prevgid::GID, refgid::GID)
    prev = getobj(prevgid)::Ref
    wait(prev)
    ensure_have_gid(prev)
    rexec(refgid.proc, wait_for_ref3, refgid, prev.gid, prevgid)
end
function wait_for_ref3(refgid::GID, gid::GID, prevgid::GID)
    ref = getobj(refgid)::Ref
    set!(ref, gid, prevgid)
end

function set!{T}(ref::Ref{T}, obj)
    @assert !isready(ref)
    # gid = makegid(obj)
    gid = nullgid()
    ref.gid = gid
    ref.obj = obj
    ref.ready = true
    notify(ref.cond)
end
function set!{T}(ref::Ref{T}, gid::GID, prevgid::GID)
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
function set_from_ref!{T}(ref::Ref{T}, other::Ref{T})
    if islocal(other)
        set!(ref, get(other))
    else
        wait(other)
        othergid = makegid(other)
        set!(ref, other.gid, othergid)
    end
end
# Don't know how to unset ref.obj
# function reset!(ref::Ref)
#     @assert isready(ref)
#     if islocal(ref.gid) ref.obj = nothing end
#     free(ref.gid)
#     ref.ready = false
#     ref.cond = Condition()
# end

function show(io::IO, ref::Ref)
    if !isready(ref)
        print(io, "$(typeof(ref))($(ref.ready))")
    elseif !islocal(ref)
        print(io, "$(typeof(ref))($(ref.ready),$(ref.gid))")
    else
        print(io, "$(typeof(ref))($(ref.ready),$(ref.gid),$(ref.obj))")
    end
end

eltype{T}(ref::Ref{T}) = T

function isready(ref::Ref)
    ref.ready
end
function wait(ref::Ref)
    if isready(ref) return end
    # Note: There must be no interruption between the "isready" and
    # the "wait"; in particular, there can be no I/O here.
    wait(ref.cond)
end

function getproc(ref::Ref)
    wait(ref)
    if isnull(ref.gid) return Comm.myproc() end
    ref.gid.proc
end
function islocal(ref::Ref)
    # getproc(ref) == Comm.myproc()
    wait(ref)
    islocal(ref.gid)
end
function get{T}(ref::Ref{T})
    wait(ref)
    @assert islocal(ref)
    ref.obj::T
end

# function =={T}(ref1::Ref{T}, ref2::Ref{T})
#     wait(ref1, ref2)
#     ref1.gid == ref2.gid
# end



function serialize{T}(s, ref::Ref{T})
    Base.serialize_type(s, Ref{T})
    write(s, ref.ready)
    if ref.ready
        ensure_have_gid(ref)
        write(s, ref.gid)
        refgid = makegid(ref)
        write(s, refgid)
     else
        refgid = makegid(ref)
        write(s, refgid)
    end
end
function deserialize{T}(s, ::Type{Ref{T}})
    ready = read(s, Bool)
    if ready
        gid = read(s, GID)
        prevgid = read(s, GID)
        Ref{T}(RefRemoteReady(), gid, prevgid)
    else
        prevgid = read(s, GID)
        Ref{T}(RefRemoteUnready(), prevgid)
    end
end



length(ref::Ref) = 1
start(ref::Ref) = false
next(ref::Ref, i) = get(ref), true
done(ref::Ref, i) = i
isempty(ref::Ref) = false

function getindex{T}(ref::Ref{T}, i::Integer)
    if i!=1 throw(BoundsError()) end
    get(ref)::T
end

end
