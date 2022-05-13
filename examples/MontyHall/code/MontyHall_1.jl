using Random; Random.seed!(1)
function whichDoor(👈; nds=3)
    🚪 = fill("🐐", nds)
    🚗 = rand(1:nds)
    🚪[🚗] = "🚗"
    if 🚪[👈] == "🚗"
        host = rand(setdiff(1:nds, 👈))
    else
        host = rand(setdiff(1:nds, [👈, 🚗]))
    end
    👌 = rand(setdiff(1:nds, [👈, host]))
    return (👈=👈, 🚗=🚗, 👌=👌, host=host)
end

# look at ten games
for i in 1:10
    println(whichDoor(rand(1:3)))
end
