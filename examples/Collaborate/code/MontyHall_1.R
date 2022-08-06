set.seed(1)
whichDoor = function(choice, nds=3) {
    doors = rep("goat", nds)
    car = sample(1:nds, 1)
    doors[car] = "car"
    if (doors[choice] == "car") { 
        host = sample((1:nds)[-choice], 1)
    } else if (nds == 3){
        host = (1:nds)[-c(choice, car)]
    } else {
        host = sample((1:nds)[-c(choice, car)], 1)
    }
    if (nds ==3) {
        switch = (1:nds)[-c(choice, host)]
    } else {
    switch = sample((1:nds)[-c(choice, host)], 1)
    }
    return(c(choice=choice, car=car, switch=switch, host=host))
}

# look at ten games
for (i in 1:10)
    print(whichDoor(sample(1:3, 1)))
