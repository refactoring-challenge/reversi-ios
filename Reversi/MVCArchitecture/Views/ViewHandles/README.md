About ViewHandles
=================

ViewHandles provide glue protocols for third-party UI components (e.g. UIViews and UIViewControllers) which may not fit to our MVC.
Notably, ViewHandles do not have to be subclass of UIView. Typically subclass of UIView needs complicated initializers
for both xib and programmatic initializations, but ViewHandles are free from the messy things.

Typically, ViewHandles are conformed by third-party UI components via extensions to expose methods to refresh UI.
And also it expose observables that signal UI events from the UI components.
The exposed observables will be subscribed by Controllers.
