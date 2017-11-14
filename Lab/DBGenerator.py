import random

shopsList = range(0, 38)

manNamesList = []
manNames = open("../Resources/names1.txt")

womenNames = open("../Resources/names2.txt")
womenNamesList = []

for line in manNames:
    manNamesList.append(line.split("\n")[0])

for line in womenNames:
    womenNamesList.append(line.split("\n")[0])

lastNames = open("../Resources/lastnames1.txt")
lastManNames = []
for line in lastNames:
    lastManNames.append(line.split(" \n")[0])

lastWomanNames = []
for line in lastManNames:
    lastWomanNames.append(line + 'a')

middlenames = open("../Resources/middlenames2.txt")
manmiddlenames = []
for line in middlenames:
    manmiddlenames.append(line.split("\n")[0])

middlenames = open("../Resources/middlenames1.txt")
womanmiddlenames = []
for line in middlenames:
    womanmiddlenames.append(line.split("\n")[0])

names = [manNamesList, womenNamesList]
lastnames = [lastManNames, lastWomanNames]
middlenames = [manmiddlenames, womanmiddlenames]

shopman = open("../SQL-INSERTS/Lab-INSERTS-Shopman.sql", "w")
shopman.write("INSERT INTO ShopDB.ShopSchema.Shopman (shopmanCode, firstName, lastName, middleName, dateOfBirth, phone, position, shopCode) VALUES \n")

count = 0
for i in range(38):
    sex = random.randint(0, 1)

    name = names[sex][random.randint(0, len(names[sex]) - 1)]
    middlename = middlenames[sex][random.randint(0, len(middlenames[sex]) - 1)]
    lastname = lastnames[sex][random.randint(0, len(lastnames[sex]) - 1)]

    year = random.randint(1977, 1997)
    month = random.randint(1, 12)
    day = random.randint(1, 27)

    code = random.randint(903, 999)

    number = random.randint(1000000, 9999999)

    shopman.write(" ( " + "'"+str(count)+"', " +
                  "'"+name+"'" + ', ' + "'"+lastname+"'" + ', ' + "'"+middlename+"'" + ', ' +
                  "'"+str(year)+'-'+str(month)+'-'+str(day)+"'"+', ' +
                  "'"+"8" + str(code) + str(number)+"'"+', ' + "'администратор', " + str(i) + "),\n")

    count += 1

    sex = random.randint(0, 1)
    name = names[sex][random.randint(0, len(names[sex]) - 1)]
    middlename = middlenames[sex][random.randint(0, len(middlenames[sex]) - 1)]
    lastname = lastnames[sex][random.randint(0, len(lastnames[sex]) - 1)]

    year = random.randint(1977, 1997)
    month = random.randint(1, 12)
    day = random.randint(1, 27)

    code = random.randint(903, 999)

    number = random.randint(1000000, 9999999)

    shopman.write("   ( " + "'" + str(count) + "', " +
                  "'" + name + "'" + ', ' + "'" + lastname + "'" + ', ' + "'" + middlename + "'" + ', ' +
                  "'" + str(year) + '-' + str(month) + '-' + str(day) + "'" + ', ' +
                  "'" + "8" + str(code) + str(number) + "'" + ', ' + "'уборщик', " + str(i) + "),\n")

    count += 1

    for k in range(0, random.randint(1, 3)):
        sex = random.randint(0, 1)

        name = names[sex][random.randint(0, len(names[sex]) - 1)]
        middlename = middlenames[sex][random.randint(0, len(middlenames[sex]) - 1)]
        lastname = lastnames[sex][random.randint(0, len(lastnames[sex]) - 1)]

        year = random.randint(1977, 1997)
        month = random.randint(1, 12)
        day = random.randint(1, 27)

        code = random.randint(903, 999)

        number = random.randint(1000000, 9999999)

        shopman.write("   ( " + "'" + str(count) + "', " +
                      "'" + name + "'" + ', ' + "'" + lastname + "'" + ', ' + "'" + middlename + "'" + ', ' +
                      "'" + str(year) + '-' + str(month) + '-' + str(day) + "'" + ', ' +
                      "'" + "8" + str(code) + str(number) + "'" + ', ' + "'продавец-консультант', " + str(i) + "),\n")

        count += 1

    sex = random.randint(0, 1)
    name = names[sex][random.randint(0, len(names[sex]) - 1)]
    middlename = middlenames[sex][random.randint(0, len(middlenames[sex]) - 1)]
    lastname = lastnames[sex][random.randint(0, len(lastnames[sex]) - 1)]

    year = random.randint(1977, 1997)
    month = random.randint(1, 12)
    day = random.randint(1, 27)

    code = random.randint(903, 999)

    number = random.randint(1000000, 9999999)

    shopman.write("   ( " + "'" + str(count) + "', " +
                  "'" + name + "'" + ', ' + "'" + lastname + "'" + ', ' + "'" + middlename + "'" + ', ' +
                  "'" + str(year) + '-' + str(month) + '-' + str(day) + "'" + ', ' +
                  "'" + "8" + str(code) + str(number) + "'" + ', ' + "'старший продавец', " + str(i) + "),\n")

    count += 1


class Item:
    def __init__(self, name, price):
        self.name = name
        self.description = "Live in Levi''s"
        self.country = "Turkey"
        self.price = price

items = [Item("512 Slim Taper Fit Stretch Jeans", 6900), Item("502 Regular Taper Fit Jeans", 6900), Item("511 Slim Fit Jeans", 4550), Item("501 Original Fit Jeans", 6500), Item("512 Original Fit Jeans", 7900),
         Item("501 Taper Fit Jeans", 7500), Item("511 Skinny Stretch Jeans", 5900), Item("527 Slim Boot Cut Jeans", 6900), Item("501 Taper Jeans", 7900), Item("501 Original Fit Cool Jeans", 8500),
         Item("504 Regular Straight Jeans", 6900), Item("Line 8 Slim Straight Jeans", 5500), Item("504 Regular Straight Jeans", 7900), Item("512 Slim Taper Fit Warp Stretch Jeans", 8900),
         Item("511 Slim Fit Stretch Jeans", 8900), Item("501 CT Jeans", 8500), Item("501 Original Fit Pants", 8500), Item("511 Slim Fit Trousers", 8900), Item("Levi''s Graphic Tee", 1900),
         Item("Levi''s Housemark Tee", 1700), Item("Graphic Sport Logo Hoodies", 4500), Item("Graphic Crew Fleece", 5500), Item("The Sherpa Trucker Jacket", 8900), Item("The Trucker Jacket", 7500),
         Item("Down Davidson Parka", 22900), Item("Thermore Utility Coat", 15900), Item("NY Runner II Sneaker", 5900), Item("Murphy Mid Boot", 8900), Item("Perris Oxford", 7500),
         Item("Premium Leather Icon Belt", 3900), Item("Sonny Belt", 3900), Item("California Embossed Indigo Belt", 3500)]

#print(len(items))

itemTable = open("../SQL-INSERTS/Lab-INSERTS-Item.sql", "w")
for item in items:
    itemTable.write("INSERT INTO ShopDB.ShopSchema.Item (itemName, description, country) VALUES ( " +
          "'"+item.name+"', " + "'"+item.description+"', " + "'"+item.country+"')\n")

store = open("../SQL-INSERTS/Lab-INSERTS-Store.sql", "w")
for i in range(38):
    for k in range(32):
        store.write("INSERT INTO ShopDB.ShopSchema.Store (shopCode, itemID, rest, price) VALUES ( " +
              str(i) + ', ' + str(k) + ', ' + str(random.randint(25, 60)) + ', ' + str(items[k].price) + ')\n')


shopmanCodes = open("../SQL-INSERTS/Lab-INSERTS-Shopman.sql")
shopmans = []

count = -1
for line in shopmanCodes:
    insert = line.split(",")
    if count != -1 and insert[6] != " 'уборщик'":
        shopmans.append(count)
    count += 1

discounts = [0, 3, 0, 5, 0, 0, 10, 0, 3, 0, 5, 0, 3, 0, 5, 0, 3, 0, 5, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 0 ,0 ,0 ,0]

card = open("../SQL-INSERTS/Lab-INSERTS-Card.sql", "w")
event = open("../SQL-INSERTS/Lab-INSERTS-Event.sql", "w")
check = open("../SQL-INSERTS/Lab-INSERTS-Check.sql", "w")
check_item_int = open("../SQL-INSERTS/Lab-INSERTS-INT.sql", "w")

count = 0
checkitemint = "INSERT INTO ShopDB.ShopSchema.[Check_Item_INT] (checkID, itemID) VALUES \n"
checkitemintcount = 0

checks = "INSERT INTO ShopDB.ShopSchema.[Check] (date, totalCost, typeOfPay, discount, shopmanCode) VALUES \n"
checkscount = 0

cards = "INSERT INTO ShopDB.ShopSchema.[Card] (checkID, type, phone, firstName, lastName) VALUES \n"
cardscount = 0

events = "INSERT INTO ShopDB.ShopSchema.[Event] (checkID, description, expDate) VALUES \n"
eventscount = 0

checkcount = random.randint(50, 100)

for i in range(len(shopmans)):
    for j in range(0, checkcount):
        year = "2017"
        month = random.randint(1, 12)
        day = random.randint(1, 27)
        hour = random.randint(10, 22)
        minute = random.randint(0, 59)
        sec = random.randint(0, 59)

        checkitems = []
        totalcost = 0
        itemCount = random.randint(1, 4)
        indexes = []

        for k in range(0, itemCount):
            index = random.randint(0, 31)

            while index in indexes:
                index = random.randint(0, 31)

            indexes.append(index)
            checkitems.append(items[index])
            totalcost += items[index].price

            if checkitemintcount % 500 == 0 and checkitemintcount != 0:
                checkitemint+="(" +" " + str(count) + "," + " " + str(index)+")" + "\n"
                checkitemint+="INSERT INTO ShopDB.ShopSchema.[Check_Item_INT] (checkID, itemID) VALUES \n"

            else:
                checkitemint += "(" + " " + str(count) + "," + " " + str(index) + ")," + "\n"

            checkitemintcount += 1

        typeOfPay = random.randint(0, 1)
        discount = discounts[random.randint(0, 33)]
        totalcost -= totalcost * discount / 100

        if (discount != 0):
            typeOfDisc = random.randint(0, 1)

            if (typeOfDisc == 0):
                type = random.randint(0, 1)

                code = random.randint(903, 999)
                number = random.randint(1000000, 9999999)

                sex = random.randint(0, 1)

                name = names[sex][random.randint(0, len(names[sex]) - 1)]
                lastname = lastnames[sex][random.randint(0, len(lastnames[sex]) - 1)]

            else:
                Description = "EVENT"
                expyear = random.randint(2017, 2018)
                expmonth = random.randint(month, 12)
                expday = random.randint(day, 27)

        if (checkscount % 500 == 0 and checkscount != 0):
            checks+="(" + " " + "'" + str(year) + '-' + str(month) + '-' + str(day) + "T" + str(hour)+ ':' + str(minute)+':'+str(sec) + "'," +\
                    " " + str(totalcost) + "," + " " + str(typeOfPay) + ',' + " " + str(discount) + ',' + " " + \
                    "'"+str(shopmans[i])+"'" + ')' + "\n"
            checks += "INSERT INTO ShopDB.ShopSchema.[Check] (date, totalCost, typeOfPay, discount, shopmanCode) VALUES \n"

        else:
            checks+="(" + " " + "'" + str(year) + '-' + str(month) + '-' + str(day) + "T" + str(hour)+ ':' + str(minute)+':'+str(sec) + "'," +\
                    " " + str(totalcost) + "," + " " + str(typeOfPay) + ',' + " " + str(discount) + ',' + " " + \
                    "'"+str(shopmans[i])+"'" + '),' + "\n"
        checkscount += 1

        if (discount != 0):

            if (typeOfDisc == 0):

                if (cardscount % 500 == 0 and cardscount != 0):
                    cards += "(" +" " + str(count) + ',' + " " + str(type) + ',' +" " + \
                           "'" + "8" + str(code) + str(number) + "'" + ',' + " " + \
                           "'" + name + "'," + " " + "'"+lastname+"')" + "\n"
                    cards+="INSERT INTO ShopDB.ShopSchema.[Card] (checkID, type, phone, firstName, lastName) VALUES \n"
                else:
                    cards += "(" + " " + str(count) + ',' + " " + str(type) + ',' + " " + \
                             "'" + "8" + str(code) + str(number) + "'" + ',' + " " + \
                             "'" + name + "'," + " " + "'" + lastname + "')," + "\n"

                cardscount += 1

            else:

                if (eventscount % 500 == 0 and eventscount != 0):
                    events += "(" + " " + str(count) + ',' + " " + "'" + Description + "'" + ',' + " " + \
                              "'" + str(year) + '-' + str(month) + '-' + str(day) + "'" + ')' + "\n"
                    events = "INSERT INTO ShopDB.ShopSchema.[Event] (checkID, description, expDate) VALUES \n"
                else:
                    events += "(" + " " + str(count) + ',' + " " + "'" + Description + "'" + ',' + " " + \
                              "'" + str(year) + '-' + str(month) + '-' + str(day) + "'" + '),' + "\n"

                eventscount += 1

        count += 1

check.write(checks)
check_item_int.write(checkitemint)
card.write(cards)
event.write(events)
