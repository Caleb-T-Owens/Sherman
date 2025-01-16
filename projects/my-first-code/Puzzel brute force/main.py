"""
octagon = 0
octagon inverse = 1
cross = 2
corss invers = 3
arrow in = 4
arrow in inverse = 5
arrow out = 6
arrow out inverse = 7


0 = dotted side
1 = 90* left
2 = 180* left
3 = 90* right

"""
peices = [[6,3,5,2], [6,0,1,7], [4,2,7,5], [2,7,7,0], [6,0,1,3], [4,5,7,0], [6,7,1,4], [4,3,5,0], [6,7,1,2], [6,1,5,6], [4,4,7,3], [0,2,3,1], [4,4,1,3], [0,4,1,3], [0,2,5,1], [0,0,1,7]]

"""
So I need to create a 2d array (4 by 4) and arrange all the peices inside it. All the peices can only go in once. I will need to sequence through all the peices, trying them in every possible location. How do I od this? It would be best to thik about this as one long line. The line will need to be reodered in all the possible configureation.

The rotations are simple, basically like counting in base 4, ie: 0001, 0002, 0003, 0010, 0011, 12, 13, 0020, 21, 22, 23

"""