About ModelDecorators
=====================

Model Decorator Pattern is variation of GoF's Decorator Pattern for MVC's Models.
The Decorator is frequently needed if the models are small enough and loosely coupled.

Generally, loosely coupled models may fail to collaborate to others if the model depends on other model's states or transitions.
Because the model may unexpectedly receive unwelcome requests (typically from UI) at unexpected timing.
As a result, the model wll face with a hard decision whether ignoring unwelcome requests or queuing unwelcome requests
in the hope of becoming valid eventually. And both decisions have pros and cons:

<dl>
<dt>Ignoring unwelcome requests</dt>
<dd><dl>
<dt>Pros</dt>
<dd>Easy and simple to implement. And be tolerant against storms of unwelcome events (typically from UI).</dd>
<dt>Cons</dt>
<dd>Some of important transitions may be ignored if a model that spontaneously request other models.</dd>
</dl></dd>
<dt>Queuing unwelcome requests</dt>
<dd><dl>
<dt>Pros</dt>
<dd></dd>
<dt>Cons</dt>
<dd>Hard and complicated to implement. And may be fragile against storms of unwelcome events (typically from UI).</dd>
</dl></dd>
</dl>

To handle the problem, Model Decorators provide safe collaborations of the models to decorate.



The Model Decorators must satisfy all of the following conditions to behave consistently:

1. Operations needs to request to the internal model must be commutative.
2. State conversions for observables must be commutative.
  
A wrapper that not conform the above conditions might be fragile against wrapping orders.
