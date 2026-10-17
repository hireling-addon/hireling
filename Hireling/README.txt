Hireling
A commission board for WoW: Forever.

People with the addon see the same offers and bids, including across zones. Gold is paid in the trade window. Hireling never moves gold.

Install
1. Exit the game.
2. Copy the Hireling folder into:
   World of Warcraft\_classic_beta_\Interface\AddOns\
3. Start the game and enable Hireling on the character screen.

The client reads addons only at startup.

Commands
/hireling or /hl          open and close
/hireling sync            join the channel and send your listings
/hireling sample          local sample cards, not sent to anyone
/hireling clearsample     remove those samples
/hireling check           look for setup problems
/hireling reset           center the window
/hireling scale 1         0.7 to 1.4
/hireling ruleset Normal  or PvP, or Roleplaying

The Channel tab sets the ruleset too. Normal, PvP, and Roleplaying do not share a board. Alliance and Horde do not share one either.

Before a CurseForge upload
Tag the file as Forever, game version 1.60.1. Do not tag it as Retail or Classic Era.
In game, run /dump select(4, GetBuildInfo()) and confirm it prints 16001.
Then /hireling check and /hireling sample.
