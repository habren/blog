library(arules)

transactions <- read.transactions("transaction.csv", format="basket", sep=",")

transactions

summary(transactions)

itemFrequency(transactions)

sort(itemFrequency(transactions), decreasing = T)

rules <- apriori(transactions, parameter = list(support = 3/7, confidence = 5/7, minlen = 2))

inspect(rules)

inspect(sort(rules, by = "lift"))

rule_measures <- interestMeasure(rules, c("coverage","fishersExactTest","conviction", "chiSquared"), transactions=transactions)  

quality(rules) <- cbind(quality(rules), rule_measures)

inspect(sort(rules, by = "conviction", decreasing = F))



