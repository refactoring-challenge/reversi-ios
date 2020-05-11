About Controllers
=================

A Controller provide uni-directional event flow between ViewHandles and Models.


:bee: IMPORTANT NOTE: Controllers should not filter unwelcome UI events for Models.
Because responsibilities to determine what events are welcome or not should be in the Models domain.
