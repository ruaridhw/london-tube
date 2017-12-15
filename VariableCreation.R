# Extract timings from RunTime and WaitTime to create JourneyTime
# table(JourneyPatternSections$RunTime)
# PT0S PT1M PT2M PT3M PT4M PT5M PT6M PT7M 
# 263 2315 1856  269   30    6    1    3 

tables$JourneyPatternSections <- within(tables$JourneyPatternSections, {
  RunTime %<>% substr(3, 3) %>% as.integer
  WaitTime %<>% substr(3, 3) %>% as.integer
  JourneyTime <- RunTime + ifelse(is.na(WaitTime), 0, WaitTime)
})

# Extract number of minutes since midnight from DepartureTime
tables$VehicleJourneys <- within(df_VehicleJourneys, {
  DepartureMins <- DepartureTime %>% hms %>% {minute(.) + 60 * hour(.)}
})
