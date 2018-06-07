library(jsonlite)
library(httr)

# === Day-ahead hourly LMPS ===
req1 <- "https://api.pjm.com/api/v1/da_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=2018-06-05T00:00:00&pnode_id=40243873"
test <- GET(req1, add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded", "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))
print(test)

text <- content(test, "text")

df <- fromJSON(text, flatten = TRUE)

# === Real-time hourly LMPs ===
