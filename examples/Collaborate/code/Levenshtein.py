def Levenshtein(s1, s2):
    n = len(s1)
    m = len(s2)
    d = [0] * (n+1)
    for x in range (n+1):
        d[x] = [0] * (m+1)
    for i in range (n):
        d[i+1][0] = i+1
    for j in range (m):
        d[0][j+1] = j+1
    for i in range (n):
        for j in range (m):
            if s1[i] == s2[j]:
                substitutionCost = 0
            else:
                substitutionCost = 1
            d[i+1][j+1] = min(d[i][j+1] + 1,         # deletion
                         d[i+1][j] + 1,              # insertion
                         d[i][j] + substitutionCost) # substitution
    return(d[n][m])
print(Levenshtein('sibling', 'setting'))
