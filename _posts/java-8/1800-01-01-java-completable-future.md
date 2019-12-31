---
layout: post

title:  "Completable Future in Java"
description: "Completable Future in Java"

permalink: "/java/completable-future"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Java]

github:
  repository_url: https://github.com/codeaches/java-8-examples
  badges: [download]
---

Java 8 introduced a lot of awesome features, one of them being **CompletableFuture class**. 

Beside implementing the Future interface, _CompletableFuture_ also implements the CompletionStage interface. **CompletionStage** promises that the computation eventually will be done.<!-- excerpt end -->

The great thing about the CompletionStage is that it offers a vast selection of methods that let us attach callbacks which will be executed on completion.

This way we can build programs in a non-blocking fashion. Let's take few examples to see some use cases of _CompletableFuture_.

## Table of contents
{: .no_toc }

1. TOC
{:toc}

### **The simplest asynchronous computation**

Let's start with the basics — creating a simple asynchronous computation.

```java
Supplier<Integer> heavyMethod = () -> {
	// Some heavy computation which eventually returns an Integer
	return 10;
};

CompletableFuture<Integer> asyncFunction = CompletableFuture.supplyAsync(heavyMethod);

/* Print the result returned by heavyMethod */
Integer result = asyncFunction.get();  
System.out.println(result);
```
```
10
```

Here, **supplyAsync** takes a Supplier containing the heavy code we want to execute asynchronously. Once, the execution of _heavyMethod_ is completed, the result will be printed.

Well, we can take it further by attaching a call back method which will print the result once _heavyMethod_ returns the result. 

### **Attach a callback**

_callback_ executes after the asynchronous computation is done.

**thenAccept** is one one option to add a callback. It takes a Consumer — _printer_ — which prints the result of the _heavyMethod_ when it's done.

```java
// Heavy computation which eventually returns an Integer
Supplier<Integer> heavyMethod = () -> {
	return 10;
};

// Print the request
Consumer<Integer> printer = (x) -> {
	System.out.println(x);
};

CompletableFuture<?> asyncFunction = CompletableFuture.supplyAsync(heavyMethod)
                                                      .thenAccept(printer);

asyncFunction.get();
```
```
10
```

What if we want to pass values from one call back to another and so on...Like a chain? **thenAccept** won't help here as it takes an input and returns nothing. In these cases, we can use another call back feature - **thenApply**. **thenApply** takes an input and returns an output.

**thenApply** takes a Function which accepts an input and returns a result.

Let's put all these into a code to see how we can use these functionalities.

### **Chaining multiple callbacks**

Let's extend our earlier example by addig a new method which multiplies the input and returns the result - **multiply**

```java
// Heavy computation which eventually returns an Integer
Supplier<Integer> heavyMethod = () -> {
	return 10;
};

// multiply the input and return the result
Function<Integer, Integer> multiply = (x) -> {
	return x * x;
};

// Print the request
Consumer<Integer> printer = (x) -> {
	System.out.println(x);
};

CompletableFuture<?> asyncFunction = CompletableFuture.supplyAsync(heavyMethod)
                                                      .thenApply(multiply)
                                                      .thenAccept(printer);

asyncFunction.get();
```
```
100
```

> Here, the response of _heavyMethod_ will be consumed by _multiply_ and the response of _multiply_ will be consumed by _printer_, which eventually prints the value 100.

### **Parallel callbacks**

Let's say, once our _heavyMethod_ is completed, we want to add as well as multiply on the same result paralelly. This can be achieved using **thenApplyAsync**.

```java
// Heavy computation which eventually returns an Integer
Supplier<Integer> heavyMethod = () -> {
	return 10;
};

// add
Function<Integer, Integer> add = (x) -> {
	return x + x;
};

// multiply
Function<Integer, Integer> multiply = (x) -> {
	return x * x;
};

// Print the request
Consumer<Integer> printer = (x) -> {
	System.out.println(x);
};

CompletableFuture<Integer> asyncFunction = CompletableFuture.supplyAsync(heavyMethod);

asyncFunction.thenApplyAsync(add).thenAccept(printer);
asyncFunction.thenApplyAsync(multiply).thenAccept(printer);

asyncFunction.get(); 
```
```
100
20
```
_add_ and _multiply_ will submitted as separate tasks to the ForkJoinPool.commonPool(). This results in both the _add_ and _multiply_ callbacks being executed when the preceding _heavyMethod_ is completed.

> Asynchronous version is a good option when we have multiple callbacks dependent on the same computation result.

### **Handling Exceptions using _exceptionally_**

Let's consider a scenario where _heavyMethod_ might throw an exception. We can use _exceptionally_ function to catch the exception and handle it gracefully. _exceptionally_ is termed as a recovery method.

In the below example, we are returning a string value **NOTHING TO PRINT** in _exceptionally_ method. **NOTHING TO PRINT** will be our recovery output when ever our _heavyMethod fails_.

```java
// Heavy computation which eventually throws NULL POINTER EXCEPTION
Supplier<String> heavyMethod = () -> {
    return ((String) null).toUpperCase();
};

// Print the message
Consumer<String> printer = (x) -> {
    System.out.println("PRINT MSG: " + x);
};

CompletableFuture<Void> asyncFunction = CompletableFuture.supplyAsync(heavyMethod)

        .exceptionally(ex -> {
            System.err.println("heavyMethod threw an exception: " + ex.getLocalizedMessage());
            return "NOTHING TO PRINT";
        }).thenAccept(printer);

asyncFunction.get();
```
```
heavyMethod threw an exception: java.lang.NullPointerException
PRINT MSG: NOTHING TO PRINT
```

### **Handling Exceptions using _whenComplete_**

**_whenComplete_** gives us more flexiblity to handle both exceptions and the results. In the below example, we are using _whenComplete_ to print the exception to error console before _exceptionally_ recoveres be sending a default message to _printer_.

```java
// Heavy computation which eventually throws NULL POINTER EXCEPTION
Supplier<String> heavyMethod = () -> {
    return ((String) null).toUpperCase();
};

// Print the message
Consumer<String> printer = (x) -> {
    System.out.println("PRINT MSG: " + x);
};

CompletableFuture<Void> asyncFunction = CompletableFuture.supplyAsync(heavyMethod)

        .whenComplete((String result, Throwable ex) -> {
            if (ex != null) {
                System.err.println("heavyMethod threw an exception: " + ex.getLocalizedMessage());
            }
        }).exceptionally(ex -> {
            return "NOTHING TO PRINT";
        }).thenAccept(printer);

asyncFunction.get();
```
```
heavyMethod threw an exception: java.lang.NullPointerException
PRINT MSG: NOTHING TO PRINT
```

### **Callback on multiple computations using _thenCombine_**

Sometimes it would be really helpful to be able to create a callback that is dependent on the result of two computations. This is where thenCombine becomes handy.

thenCombine allows us to register a BiFunction callback depending on the result of two CompletionStages.

To see how this is done, let’s in addition to finding a receiver also execute the heavy job of creating some content before sending a message.

```java
// Heavy computation which eventually returns an Integer
Supplier<Integer> heavyMethod1 = () -> {
    return 10;
};

// Heavy computation which eventually returns an Integer
Supplier<Integer> heavyMethod2 = () -> {
    return 15;
};

// Print the request
Consumer<Integer> printer = (x) -> {
    System.out.println(x);
};

CompletableFuture<Integer> asyncFunction1 = CompletableFuture.supplyAsync(heavyMethod1);
CompletableFuture<Integer> asyncFunction2 = CompletableFuture.supplyAsync(heavyMethod2);

BiFunction<Integer, Integer, Integer> sum = (result1, result2) -> {
    return (result1 + result2);
};

CompletableFuture<Void> combinedFunction = asyncFunction1.thenCombine(asyncFunction2, sum).thenAccept(printer);

combinedFunction.get(); 
```
```
25
```

In the above example, we started two asynchronous methods — heavyMethod1 and heavyMethod2. _thenCombine_ is used to trigger _sum_ which takes the result of both asynchronous methods and returns the result. _printer_ prints this result.

### **Callback on multiple computations using _runAfterBoth_**

**_runAfterBoth_** is another variant of thenCombine. _runAfterBoth_ takes a Runnable not caring about the actual values of the preceding computation — only that they both are actually complete.

```java
// Heavy computation which eventually returns an Integer
Supplier<Integer> heavyMethod1 = () -> {
	return 10;
};

// Heavy computation which eventually returns an Integer
Supplier<Integer> heavyMethod2 = () -> {
	return 15;
};

CompletableFuture<Integer> asyncFunction1 = CompletableFuture.supplyAsync(heavyMethod1);
CompletableFuture<Integer> asyncFunction2 = CompletableFuture.supplyAsync(heavyMethod2);

Runnable sum = () -> {
	System.out.println("Heavy Load methods completed successfully");
};

CompletableFuture<Void> combinedFunction = asyncFunction1.runAfterBoth(asyncFunction2, sum);

combinedFunction.get();
```
```
Heavy Load methods completed successfully
```

### **Callback on either of computations using _runAfterBoth_**

Let’s say we have two sources of finding car details either through _carfax_ or _autocheck_. We can ask both and take the result from who ever returns first.

This can be achieved by **acceptEither** as seen below. the consumer _carDetails_ will be executed when either _carfax_ or _autocheck_ returns the result.

```java
// Heavy computation which eventually returns an car details
Supplier<String> carfax = () -> {
    return "2013 Toyota Corolla";
};

// Heavy computation which eventually returns an car details
Supplier<String> autocheck = () -> {
    return "2013 Toyota Corolla";
};

CompletableFuture<String> carfaxResult = CompletableFuture.supplyAsync(carfax);
CompletableFuture<String> autocheckResult = CompletableFuture.supplyAsync(autocheck);

Consumer<String> carDetails = (car) -> {
    System.out.println("Car details: " + car);
};

CompletableFuture<Void> either = carfaxResult.acceptEither(autocheckResult, carDetails);

either.get();
```
```
Car details: 2013 Toyota Corolla
```

This concludes the features of **CompletableFuture** class. I hope you like this aticle.

**Your feedback is always appreciated. Happy coding!**
