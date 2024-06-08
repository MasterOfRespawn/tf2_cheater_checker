# TF2 cheater checker (better at detecting aimbots than smart cheaters)

this is a tool I started developing after being annoyed one time too much by bots in TF2.
to use it, you need your [steam web api key](https://partner.steamgames.com/doc/webapi_overview/auth)

## add a steam web api key
once you have your key, start the tool and go to `FILE->change key`, enter your key and hit enter to confirm.
your key will be locally stored in the working directory within a file called `key.txt` to usage of the tool without repeated key setting.

## check a user's profile
to check a profile select `Player->add by id` or `Player->add by name` based on whether you have a steamid64 to resolve or a steam vanity url name.
once confirmed, an overwiew of the player's profile and statistics along a suspicion count will be displayed
to check multiple steam IDs in bulk, select `Player->add in batch` for the tool to try and automatically check every steam id in the entered string.
this can be used in cunjunction with the `status` command in team fortress 2 which outputs the current server status as well as the steam IDs of all connected players.

## suspicion
there currently are 10 suspicion conditions:
- the player is VAC-banned
- the player reached a class achievement milestone without playing the associated class
- the player reached a class achievement milestone without the prior milestone being reached
- the player achieved the carnival of carnage milestone without reaching four carnival of carnage achievements
- the player has played more than 50 hours but less than 5 of the 9 classes
- the players sniper headshot to kill rate is above 60%
- the player has earned all 520 achievements after 2013
- the player has reached any youtube replay view count achievements after 2013 which is invalid due to an api change
- the player has reached more than 5 achievements in one second (which is very unlikely in normal play)
- the player has spent less than 10% of his in game time playing as a class [DEPRECATED, PROBABLY REMOVED SOON due to inaccuracy]
the applicable suspicion conditions are checked and if any are checked, a total suspicion count will be displayed

## batch mode
by running in the command line, the tool can be started in batch mode
in batch mode, the tool will check a given list of steam IDs, dump the results in shortened form to stdout and exit once it is done.
because of steam api rate limits, it currently checks at a rate of 1 steam id per second
to run the tool in batch mode, run:
`tf2cc [--headless] [--short] -- {IDs}`
where `--headless` is optional to disable the gui
and `--short` is optional to shorten the output a bit
and `IDs` is a space seperated list of steam ids to check
