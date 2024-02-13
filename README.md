# wheres-my-vds-team

Pre-season:
* rename any `races` and `teams` seed files from the previous season
* open a rails console `rails c`
* run `Vds::Scraper.races` to scrape the VDS race calendars
* copy `lib/data/races.csv` to `db/seeds/races.csv`
* where necessary, amend the `pcs_name` (column 3) to match the name present on Pro Cycling Stats

After teams have been revealed:
* open a rails console `rails c`
* run `Vds::Scraper.teams` to scrape team rosters
* copy `lib/data/teams.csv` to `db/seeds/teams.csv`
* where necessary, amend teams names to formatting issues. Historical problems include:
    * double quotes needed around team names that contain commas
* where necessary, amend rider names to fix discrepencies between VDS and PCS. Historical problems include:
    * `Simon Right Yates` -> `Simon Yates`
    * `Mattias Skjelmose Jensen` -> `Mattias Skjelmose`
    * `Magnus Cort Nielsen` -> `Magnus Cort`
    * `Jonas Vingegaard Rasmussen` -> `Jonas Vingegaard`
    * `Sam Watson` -> `Samuel Watson`
    * `Samuel Welsford` -> `Sam Welsford`
    * `Santiago Buitrago Sanchez` -> `Santiago Buitrago`
    * `Enric Mas Nicolau` -> `Enric Mas`
    * `Sergio Andres Higuita` -> `Sergio Higuita`
    * `Tobias Svendsen Foss` -> `Tobias Foss`
    * `Carlos Verona Quintanilla` -> `Carlos Verona Quintanilla`
    * `Coryn Labecki (Rivera)` -> `Coryn Labecki`
    * `Kata Blanka Vas` -> `Blanka Vas`
    * `Maaike van der Duin` -> `Maike van der Duin`
