# using FunHPC
using Base.Test

unshift!(LOAD_PATH, "../src")

include("FunsTest.jl")
include("FoldableTest.jl")
include("FunctorTest.jl")
include("MonadTest.jl")

# include("CommTest.jl")
# include("MultiDictsTest.jl")
