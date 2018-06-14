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









# Simple moving average testing
library(pracma)

convertID <- c("Cardinal2"="40243873",
               "Cardinal3"="40243869",
               "Greenville1"="40243881",
               "Greenville2"="40243883",
               "Greenville3"="40243885",
               "Greenville4"="40243887",
               "Mone1"="32419345",
               "Mone2"="32419347",
               "Mone3"="32419349")
plant <- "Cardinal1"
date <- "2016-06-10"

date0Formatted <- paste0(as.character(as.Date(date, origin="1970-01-01")), "T00:00:00")
rtReq <- paste0("https://api.pjm.com/api/v1/rt_hrl_lmps?download=true&rowCount=50000&startRow=1&datetime_beginning_ept=",date0Formatted,"&pnode_id=",convertID[[plant]])
rtResp <- GET(rtReq,
              add_headers(.headers = c("Content-Type" = "application/x-www-form-urlencoded",
                                       "Ocp-Apim-Subscription-Key" = "f6155aeeff864197a6a0aa1aec1af5fe")))
rtText <- content(rtResp, "text")
rtData <- fromJSON(rtText, flatten = TRUE)

mergedData <- data.frame(timestamp = rtData$datetime_beginning_ept,
                         plant = rtData$pnode_name,
                         realtime = rtData$total_lmp_rt)

meltedData <- reshape2::melt(mergedData, id = c("timestamp", "plant"))

avgs <- pracma::movavg(mergedData$realtime, 3, type = "s")