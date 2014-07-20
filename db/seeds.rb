#new data here
# Find What: (\d)(\d)(\d)(\w)(\d)
# Replace With: {code: "$1$2$3$4$5", kvalue: 0},
Accesscode.delete_all

Accesscode.create!([
{id: 1, code: "000E7", kvalue: 0},
{id: 2, code: "000R1", kvalue: 0},
{id: 3, code: "000O7", kvalue: 0},
])