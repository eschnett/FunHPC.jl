# using FunHPC
using Base.Test

unshift!(LOAD_PATH, "../src")

include("FunsTest.jl")
include("FoldableTest.jl")
include("FunctorTest.jl")
include("StencilFunctorTest.jl")
include("MaybesTest.jl")
include("MonadTest.jl")
include("MultiDictsTest.jl")

include("CommTest.jl")
include("GIDsTest.jl")
include("FunRefsTest.jl")
include("ParTest.jl")

using Comm
run_main() do
    FunsTest.main()
    FoldableTest.main()
    FunctorTest.main()
    StencilFunctorTest.main()
    MaybesTest.main()
    MonadTest.main()
    MultiDictsTest.main()

    CommTest.main()
    GIDsTest.main()
    FunRefsTest.main()
    ParTest.main()
end
