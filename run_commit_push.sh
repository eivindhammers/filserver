#!/bin/bash

cd "$(dirname "$0")"

git pull --ff-only

Rscript get_scores.R

git add scores_21-22.csv
git commit -m "update scores"
git push origin master

echo Premier League scores updated and pushed to Github.
