#### process an heavy image transform task on background

Simple solution:
put it in background queue, when it finished, use call back func to update the UI.

problem: It's based on original image, could not run sequence task in order.

Improve:
Use a serial task process queue and put all transfroming task in the queue.

Attention:  read and write `latest` variable in different thread. Use `Thread santizer` to detect data race.

Sulotion:  use a variable lock (serial queue)

TODO: need lock for update callback?

