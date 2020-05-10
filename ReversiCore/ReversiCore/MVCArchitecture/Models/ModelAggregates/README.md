About ModelAggregates
=====================

Model Aggregates Pattern is variation of Aggregates for MVC's Models.
It is frequently needed if the models are small enough and loosely coupled.

Generally, loosely coupled models may fail to collaborate to others if the model depends on other model's states or transitions.
Because models may ignore unwelcome requests typically from UI. You can drop unwelcome requests in UI layer but
it may contaminate UI layers with domain logic. Another approach is queueing requests in hope that the requests be welcome eventually.

It is a hard decision whether ignoring unwelcome requests or queuing unwelcome requests. And both approaches have pros and cons:


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

To handle the problem, Model Aggregates provide safe collaborations of the child-models.
