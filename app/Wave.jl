unshift!(LOAD_PATH, ".", "../src")

using Comm, Par
using Cells, Defs, Domains, Grids, Memoizeds, Norms

function main()
    println("Wave[FunHPC.jl]")
    
    println("Running on $(Comm.nprocs()) processes")

    filename = "wave.$(Comm.nprocs()).txt"
    file = open(filename, "w")
    
    println("Initialization")
    @time begin
        s = par(R=Domain) do; Domains.initial(Defs.tmin) end
        m = Memoized(0, s)
        s1 = rk2(m)             # to warm up
        info_output(STDOUT, m, is_first=true)
        file_output(file, m, is_first=true)
        wait(m)
        wait(s1[])
    end
    
    println("Evolution")
    # TODO: Don't check s.t at every iteration
    @time begin
        while ((Defs.nsteps<0 || m.n<Defs.nsteps) &&
               (Defs.tmax<0.0 || s[].t < Defs.tmax - 0.5*Defs.dt()))
            s = rk2(m)
            m = Memoized(m.n+1, s)
            info_output(STDOUT, m)
            file_output(file, m)
        end
        info_output(STDOUT, m, was_last=true)
        file_output(file, m, was_last=true)
    end
    
    close(file)
    
    println("Done.")
end

run_main(main)
