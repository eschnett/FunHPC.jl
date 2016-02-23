module Hello

using Comm

function main()
    println("Hello, World! This is process $(myproc()) of $(nprocs()).")
end

run_main(main)

end
