# TF2 cheater checker (better at detecting aimbots than smart cheaters)

this is a tool I started developing after being annoyed one time too much by bots in TF2.
to use it, you need your [steam web api key](https://partner.steamgames.com/doc/webapi_overview/auth)

## add a steam web api key
once you have your key, start the tool and go to `FILE->change key`, enter your key and hit enter to confirm.
your key will be locally stored in the working directory within a file called `key.txt` to usage of the tool without repeated key setting.

## check a user's profile
to check a profile select `Player->add by id` or `Player->add by name` based on whether you have a steamid64 to resolve or a steam vanity url name.
once confirmed, an overwiew of the player's profile and statistics along a suspicion count will be displayed

## suspicion
there currently are 7 suspicion conditions:
- the player is VAC-banned
- the player reached class achievement milestones without playing the associated class
- the player reached class achievement milestone without a prior milestone being achieved
- the player achieved the carnival of carnage milestone without reaching four carnival of carnage achievements
- the player has spent less than 10% of his in game time playing as a class (at least counted by statistics, custom  servers may not be counted by TF2's statistics)
- the player has played more than 50 hours but less than 5 of the 9 classes
- the players sniper headshot to kill rate is above 60%
the applicable suspicion conditions are checked and if any are checked, a total suspicion count will be displayed

## batch mode
by running in the command line, the tool can be started in batch mode
in batch mode, the tool will check a given list of steam IDs, dump the results in shortened form to stdout and exit once it is done.
because of steam api rate limits, it currently checks at a rate of 1 steam id per second
to run the tool in batch mode, run:
`tf2cc [--headless] -- {IDs}`
where `--headless` is optional to disable the gui
and `IDs` is a space seperated list of steam ids to check
