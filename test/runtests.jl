# using FunHPC
using Base.Test

unshift!(LOAD_PATH, "../src")

include("FunsTest.jl")
include("FoldableTest.jl")
include("FunctorTest.jl")
include("StencilFunctorTest.jl")
include("MonadTest.jl")
include("MultiDictsTest.jl")

using Comm
Comm.init()
include("CommTest.jl")
Comm.finalize()
