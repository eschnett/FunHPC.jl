module GIDs

using MultiDicts

using Comm

import Base: read, write
import Base: isnull

export GID
export nullgid, isnull, makegid, islocal, hasobj, getobj, alloc, free
export read, write

typealias ObjID typeof(object_id(nothing))

immutable GID
    proc::ProcID
    id::ObjID
end

# TODO: Use ObjectIDDict?
global MGR = MultiDict{ObjID,Any}()
mgr() = global MGR::MultiDict{ObjID,Any}

function nullgid()
    GID(0,0)
end
function isnull(gid::GID)
    return gid.proc==0
end
function makegid(obj::Any)
    proc = myproc()
    id = object_id(obj)::ObjID
    mgr()[id] = obj
    GID(proc, id)
end
function islocal(gid::GID)
    isnull(gid) || gid.proc == myproc()
end
function hasobj(gid::GID)
    @assert islocal(gid) && !isnull(gid)
    haskey(mgr(), gid.id)
end
function getobj(gid::GID)
    @assert islocal(gid) && !isnull(gid)
    mgr()[gid.id]
end
function alloc(gid::GID)
    @assert islocal(gid) && !isnull(gid)
    addindex!(mgr(), gid.id)
end
function free(id::ObjID)
    delete!(mgr(), id)
    nothing
end
function free(gid::GID)
    @assert !isnull(gid)
    if islocal(gid) return free(gid.id) end
    rexec(gid.proc, free, gid.id)
    nothing
end

function read(s::IO, ::Type{GID})
    proc = read(s, ProcID)
    id = read(s, ObjID)
    GID(proc, id)
end
function write(s::IO, gid::GID)
    @assert !isnull(gid)
    write(s, gid.proc, gid.id)
end

end
