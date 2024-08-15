# What is the asynchronous.

Asynchronous don't prevent successor logics.

# What is the async function.

In a nutshell, async function is a function which returns Promise object.
Promise object includes then, catch and finally property.
We can add some handlings to the each property(then, catch and finally) after the function returns Promise object.
The handlings tend to be a success or error handling.

# What is the await.

Await can only be defied in async functions.
Await allows asynchronous to behave as synchronous.
In other words, asynchronous with await prevents successor logics in an async function.
Remember asynchronous originally don't prevent successor logics.
Note that asynchronous with await doesn't prevent successor logics out of an async function.
Async functions are kinda scope for await to prevent successor logics which need something from the await.
