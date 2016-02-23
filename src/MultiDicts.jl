module MultiDicts

import Base: delete!, empty!, get!, getindex, haskey, isempty, setindex!, show

export MultiDict
export addindex!, delete!, empty!, get!, haskey, getindex, isempty, setindex!,
       show



immutable Count{T}
    value::T
    count::Int
    function Count(value, count=1)
        #@assert count>=0
        new(value, count)
    end
end
invariant{T}(c::Count{T}) = c.count >= 0

function inc{T}(c::Count{T})
    Count{T}(c.value, c.count+1)
end
function dec{T}(c::Count{T})
    Count{T}(c.value, c.count-1)
end



immutable MultiDict{K,V} <: Associative{K,V}
    counts::Dict{K,Count{V}}
    MultiDict() = new(Dict{K,Count{V}}())
end
function invariant{K,V}(d::MultiDict{K,V})
    for (k,v) in d.counts
        invariant(v) || return false
    end
    return true
end

# Insert another value for an existing key
function addindex!{K,V}(d::MultiDict{K,V}, k)
    k::K
    #@assert invariant(d)
    c = d.counts[k]
    d.counts[k] = inc(c)
    #@assert invariant(d)
    c.value
end

function delete!{K,V}(d::MultiDict{K,V}, k)
    k::K
    #@assert invariant(d)
    c = d.counts[k]
    c = dec(c)
    if c.count == 0
        delete!(d.counts, k)
    else
        d.counts[k] = c
    end
    #@assert invariant(d)
    d
end

function empty!{K,V}(d::MultiDict{K,V})
    #@assert invariant(d)
    empty!(d.counts)
    #@assert invariant(d)
    d
end

function get!{K,V}(d::MultiDict{K,V}, k, v)
    k::K
    v::V
    #@assert invariant(d)
    if haskey(d, k) return d[k] end
    d[k] = v
    #@assert invariant(d)
    v
end

function getindex{K,V}(d::MultiDict{K,V}, k)
    k::K
    #@assert invariant(d)
    d.counts[k].value
end

function haskey{K,V}(d::MultiDict{K,V}, k)
    k::K
    #@assert invariant(d)
    haskey(d.counts, k)
end

function isempty{K,V}(d::MultiDict{K,V})
    #@assert invariant(d)
    isempty(d.counts)
end

# Note: We don't allow replacing values
function setindex!{K,V}(d::MultiDict{K,V}, v, k)
    k::K
    v::V
    #@assert invariant(d)
    if haskey(d.counts, k)
        c = d.counts[k]
        #@assert c.value == v
        c = inc(c)
    else
        c = Count{V}(v)
    end
    d.counts[k] = c
    #@assert invariant(d)
    v
end

function show{K,V}(io::IO, d::MultiDict{K,V})
    #@assert invariant(d)
    print(io, "$(MultiDict{K,V})($(d.counts))")
end

#@assert (println("WARNING: Module MultiDicts has assertions enabled -- will run slowly"); true)

end
