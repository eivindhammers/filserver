library(jsonlite)
library(httr)
library(rlist)
library(blastula) 
library(glue)
library(plyr)
library(dplyr)

api_key <- source("api-key.R")[[1]]

# Read previous scores
scores_prev <- read.csv2("scores.csv", stringsAsFactors = FALSE)

matches <- GET("http://api.football-data.org/v2/competitions/PL/matches", 
            add_headers("X-Auth-Token" = api_key)) %>%
  content

matches_fin <- list.filter(matches$matches, status == "FINISHED") %>%
  list.select(homeTeam, awayTeam, matchday, utcDate, score)

matches_df <- data.frame(matrix(unlist(matches_fin), 
                                nrow = length(matches_fin), 
                                byrow = TRUE), stringsAsFactors = FALSE) %>%
  select(-X1, -X3, -X7, -X8, -X11, -X12) %>%
  setNames(c("team", "opponents", "round", "kickoff_time", "team_h_score", "team_a_score")) 

oldnames <- unique(sort(c(as.character(unique(matches_df$team)),
                          as.character(unique(matches_df$opponents)))))
newnames <- c("Bournemouth", "Arsenal", "Aston Villa", "Brighton", "Burnley",
              "Chelsea", "Crystal Palace", "Everton", "Leicester", "Liverpool", 
              "Man City", "Man United", "Newcastle", "Norwich", "Sheffield Utd",
              "Southampton", "Tottenham", "Watford", "West Ham", "Wolves")

matches_df <- matches_df %>%
  mutate(team = mapvalues(team, oldnames, newnames),
         opponents = mapvalues(opponents, oldnames, newnames),
         round = as.integer(round),
         team_h_score = as.integer(team_h_score),
         team_a_score = as.integer(team_a_score))

write.csv2(matches_df, "scores.csv", row.names = FALSE)

scores_diff <- anti_join(matches_df, scores_prev) 

# source("create_creds.R")

if (nrow(scores_diff) > 0) {
  results_txt <- scores_diff %>%
    mutate(result_string = paste0(team, "  ", team_h_score, " - ", team_a_score, "  ", opponents)) %>%
    pull(result_string) %>%
    paste(collapse = "\n")
  
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
