# Re-Join
Rejoin domain task automation.

When for example trust relationship is broken between server and domain computers you can't send gpo/scheduled task remotely and have to login with local administrator account, take computer out of domain, restart, log in locally, re-add, restart...

2 cases :
  - If in a domain : Remove computer from domain, restart, log local administrator in automatically, run script again to add computer to domain, restart.
  - If not in a domain : Add computer to domain, restart.

Launch using Join.bat preferably, to bypass execution policy and run as administrator with a simple double click!

Needless to say, beware when leaving your passwords in clear.
