library(blastula) 
library(glue)
library(plyr)
library(dplyr)
library(fplscrapR)

api_key <- source("api-key.R")[[1]]

# Read previous scores
scores_prev <- read.csv2("scores.csv", stringsAsFactors = FALSE)

matches <- get_game_list() %>%
  #filter(finished == TRUE) %>%
  select(team = home, opponents = away, round = GW, kickoff_time = kickoff, team_h_score, team_a_score)

oldnames <- unique(sort(c(as.character(unique(matches$team)),
                          as.character(unique(matches$opponents)))))
newnames <- c("Arsenal", "Aston Villa", "Brighton", "Burnley",
              "Chelsea", "Crystal Palace", "Everton", "Fulham", "Leeds", "Leicester", "Liverpool", 
              "Man City", "Man United", "Newcastle", "Sheffield Utd",
              "Southampton", "Tottenham", "West Bromwich", "West Ham", "Wolves")

matches <- matches %>%
  mutate(team = mapvalues(team, oldnames, newnames),
         opponents = mapvalues(opponents, oldnames, newnames),
         round = as.integer(round),
         team_h_score = as.integer(team_h_score),
         team_a_score = as.integer(team_a_score))

write.csv2(matches, "scores_20-21.csv", row.names = FALSE)

scores_diff <- anti_join(matches, scores_prev)

# source("create_creds.R")

if (nrow(scores_diff) > 0) {
  results_txt <- scores_diff %>%
    mutate(result_string = paste0(team, "  ", team_h_score, " - ", team_a_score, "  ", opponents)) %>%
    pull(result_string) %>%
    paste(collapse = "<br>")
  
  current_date_time <- add_readable_time(use_tz = TRUE)
  
  # Generate the body text for the email message
  email_text <- 
  glue(
  "
  Hei,
  
  Premier League-resultatene har blitt oppdatert med følgende kamper:
  
  {results_txt}
  
  Mvh PL-roboten
  "
  )
  
  email_object <-
    compose_email(
      body = md(email_text),
      footer = glue("Email sent on {current_date_time}.")
    )
  
  email_object %>%
    smtp_send(
      to = "emh@osloeconomics.no",
      from = "eivindhammers@gmail.com",
      subject = "Oppdatering av Premier League-resultater",
      credentials = creds_file("gmail_creds")
    )
}
