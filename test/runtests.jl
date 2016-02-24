# using FunHPC
using Base.Test

unshift!(LOAD_PATH, "../src")

include("FunsTest.jl")
include("FoldableTest.jl")
include("FunctorTest.jl")
include("MonadTest.jl")

using Comm
Comm.init()
include("CommTest.jl")
# include("MultiDictsTest.jl")
Comm.finalize()
