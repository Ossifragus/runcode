countMTH = function(n, nds=3){
    games = replicate(n, whichDoor(sample(1:3, 1), nds=nds))
    mean(games[1,] == games[2,])
    mean(games[3,] == games[2,])
    return (c(mean(games[1,] == games[2,]), mean(games[3,] == games[2,])))
    }

# simulate 100 games to approximate the probabilities
probabilities = paste(countMTH(100), collapse=", ")
