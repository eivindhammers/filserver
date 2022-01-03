library(blastula)
library(glue)
library(plyr)
library(dplyr)
library(fplscrapR) #remotes::install_github("wiscostret/fplscrapR")

matches <- get_game_list() %>%
  filter(finished == TRUE) %>%
  select(team = home, opponents = away, round = GW, kickoff_time = kickoff, team_h_score, team_a_score)

oldnames <- unique(sort(c(as.character(unique(matches$team)),
                          as.character(unique(matches$opponents)))))
newnames <- c("Arsenal", "Aston Villa", "Brighton", "Brentford", "Burnley",
              "Chelsea", "Crystal Palace", "Everton", "Leeds", "Leicester", "Liverpool",
              "Man City", "Man United", "Newcastle", "Norwich",
              "Southampton", "Tottenham", "Watford", "West Ham", "Wolves")

matches <- matches %>%
  mutate(team = mapvalues(team, oldnames, newnames),
         opponents = mapvalues(opponents, oldnames, newnames),
         round = as.integer(round),
         team_h_score = as.integer(team_h_score),
         team_a_score = as.integer(team_a_score)
         )

write.csv2(matches, "scores_21-22.csv", row.names = FALSE)
