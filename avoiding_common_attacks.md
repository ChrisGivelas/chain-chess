# Avoiding common attacks

Due to the nature of my project, there aren't really any attack surfaces similar to the ones discussed throughout the course. It seems that all of them involve trying to send ether in some form or another, which does not happen in any of my contracts.

If I were to implement the tournament functionality, that would open up my project to the attack surfaces discussed throughout the course. In this case, I would be sure to implement the withdrawl pattern for winners receiving their tournament winnings.
