library(jsonlite)
library(httr)

# === Day-ahead hourly LMPS ===
req1 <- "https://api.pjm.com/api/v1/da_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=2018-06-05T00:00:00&pnode_id=40243873"
resp1 <- GET(req1,
             add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded",
                                      "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))

text1 <- content(resp1, "text")
df1 <- fromJSON(text1, flatten = TRUE)

# === Real-time hourly LMPs ===
req2 <- "https://api.pjm.com/api/v1/rt_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=2018-06-01T00:00:00&pnode_id=40243873"
resp2 <- GET(req2,
             add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded",
                                      "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))

text2 <- content(resp2, "text")
df2 <- fromJSON(text2, flatten = TRUE)