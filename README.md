# scrapyard: prototype cards
a project for generating prototype cards for scrapyard (status: semi-esoteric)

run `bash print.sh` to do it, it's the key to all this

as a corollary, look at `print.sh` to see what happens and in what order

commercial license, sorry gents nothing to see here

---------

(OLD) Notes - ignore these
=====

**Power/Cost Ratio (PCR)**

PCR is a fast and loose metric that tries to get a rough handle on how OP a given part & schematic are.

In coarse terms, the metric is the overall power of the part / the overall cost of the schematic. Something like:

    overall power = (sum of raw stats) * 2^(# of effects) * (% of false flags)

    overall cost = (required rank) * (sum of log(average group cost))

*raw stats* are the following. later while refining the quality metric we can assign coefficients to these values upon calculation

 - the part's armor
 - the part's resilience
 - the part's inverse weight (?)
 - the part's weapon damage
 - the part's weapon accuracy -(as a percentage)-
 - the part's weapon's number of valid targets

*effects* on a part are either desirable (**+**) or undesirable (**-**). add these up accordingly to get the number of effects

> for example, two desirable effects (**+**)(**+**) and one undesirable effect (**-**) make for an effect count of 1.

there are three "*flags*". However, one of them has a "half-false" state:

- flys
- digs
- weapon (**false** for no weapon, melee for "*half-false*", ranged for **true**)

> so if a part were to have flying and a melee weapon, the % of false flags would be **(1 + 0.5) / 3**,  *or 50%*.

*required rank* is just the engineering rank needed to do the schematic

an *average group cost* refers to the average of the costs of all the possibilities in a requirement group. all the alternative means for meeting the same end. each "means" has a cost equal to the total raw value of that means divided by the difficulty of obtaining those specific pieces (aka the number of scraps like it / the total number of scraps). the raw "override" has no difficulty associated with it.

> so if a group had three possibilities:
	> 1. Automobile (value 10, rarity 0.01) **difficulty 1000**
	> 2. alloy Frame (value 2, rarity 0.25) and Heavy Actuator (value 6, rarity 0.04) **difficulty 800**
	> 3. Buyout **20**
> The average cost of this group would be **606** ( log(606) = 2.78 )
