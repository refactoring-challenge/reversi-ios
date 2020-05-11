About ViewHandles
=================

ViewHandles provide glue protocols for third-party UI components (e.g. UIViews and UIViewControllers) which may not fit to our MVC.
Notably, ViewHandles do not have to be subclass of UIView. Typically subclass of UIView needs complicated initializers
for both xib and programmatic initializations, but ViewHandles are free from the messy things.

Typically, ViewHandles take third-party UI components and expose synchronous bundled refresh methods.
Synchronous bundled refresh methods are important to make testing for depended-on components easy.
And also it expose observables (such as ReactiveSwift.Signal or RxSwift.Signal) that signal UI events from the UI components.
The exposed observables will be subscribed by Controllers.
