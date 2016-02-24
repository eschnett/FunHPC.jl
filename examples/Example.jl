module Example

using Comm, Par, Refs

function main()
    println("Setting up $(nprocs()) matrices...")
    # @remote performs a calculation remotely, and leaves the result
    # on the remote process. The calculation proceeds in the
    # background, while the local process continues.
    As = [@remote p rand(1000, 1000) for p in 1:nprocs()]
    
    println("Squaring each matrix...")
    # To access a remote object, use get() on the process where the
    # object lives
    Bs = [@remote A get(A)^2 for A in As]
    
    println("Calculating and collecting matrix norms...")
    # @rpar performs a remote calculation, but returns the result to
    # the caller instead of leaving it on the remote system. The
    # calculation and collecting still proceeds in the background.
    ns = [@rpar B norm(get(B)) for B in Bs]
    
    println("Outputting norms:")
    # This call to get() implicitly waits for all the previous
    # calculations to finish.
    println([get(n) for n in ns])
    
    println("Done.")
end

run_main(main)

end
