function countMTH(n; nds=3)
    n_keep, n_switch = 0, 0
    for i in 1:n
        game = whichDoor(rand(1:3), nds=nds)
        if game.👈 == game.🚗
            n_keep += 1
        elseif game.👌 == game.🚗
            n_switch += 1
        end
    end
    return (n_keep, n_switch) ./ n
end

# simulate 100 games to approximate the probabilities
probabilities = countMTH(100)
