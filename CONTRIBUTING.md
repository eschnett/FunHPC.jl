Remaining TODOs in FunHPC.jl
-------------------

1. [Don't check s.t at every iteration in app/Wave.jl](https://github.com/eschnett/FunHPC.jl/blob/master/app/Wave.jlL26)

2. [Use Base.return_types in src/Funs.jl](https://github.com/eschnett/FunHPC.jl/blob/master/src/Funs.jl#L10)

3. [Futurize at least twice in app/Memoizeds.jl](https://github.com/eschnett/FunHPC.jl/blob/master/app/Memoizeds.jl#L49)

4. [Use ObjectIODict (?) in src/GIDs.jl](https://github.com/eschnett/FunHPC.jl/blob/master/src/GIDs.jl#21)

5. [Fix printing in app/Domains.jl](https://github.com/eschnett/FunHPC.jl/blob/master/app/Domains.jl#L25)

6. [TRUE case in src/Comm.jl](https://github.com/eschnett/FunHPC.jl/blob/master/src/Comm.jl#L15)

7. [Use TestSome in src/Comm.jl](https://github.com/eschnett/FunHPC.jl/blob/master/src/Comm.jl#L88)

8. [Introduce LocalFunRef without a GID for the item](https://github.com/eschnett/FunHPC.jl/blob/master/src/Par.jl#85)

9. [Obtain GID lazily, only when needed? in src/Par.jl](https://github.com/eschnett/FunHPC.jl/blob/master/src/Par.jl#87)

10. [Replace ready, cond by Maybe(Condition) in src/FunRefs.jl](https://github.com/eschnett/FunHPC.jl/blob/master/src/FunRefs.jl#L21)
