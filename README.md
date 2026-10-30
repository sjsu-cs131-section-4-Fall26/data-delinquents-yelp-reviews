# data-delinquents-yelp-reviews

## Team Members:
- Natalie Laurence – Product Manager 
- Elias Elmziat – Data Engineer 
- Prajacta Bagayatkar – Data Engineer 
- Anthony Tan – Data Storyteller

## Description of dataset
Reviews of businesses, including restaurants, cafes, stores and more listed on yelp.

## Data card
- Source: https://business.yelp.com/data/resources/open-dataset/ (JSON download, 4.35 GB tar)
- File: `yelp_academic_dataset_review.json` (5.0 GB, 6,990,280 lines), pass its path to the scripts
- Format: JSON Lines, UTF-8, no header, 9 keys: review_id, user_id, business_id, stars, useful, funny, cool, text, date
- Run: `bash run_pa1.sh <file>` and `bash run_pa2.sh <file>`; outputs go to out/ and logs/ (git-ignored)
- Quality notes: `text` has escaped quotes, newlines and tabs; 5 rows had malformed vote fields and were dropped in Part 2
