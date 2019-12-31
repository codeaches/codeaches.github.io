---
layout: post

title:  "Function Composition in Java"
description: "Function Composition in Java"

permalink: "/java/functional-composition"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Java]

github:
  repository_url: https://github.com/codeaches/java-8-examples
  badges: [download]
---

In this post let's look at function composition using two compose functions provided in the Function interface - **compose** and **andThen**.

Function composition results in a reuseable function which itself is a combination of other functions.

Basically, there are two ways to achieve Function composition. They are **compose** and **andThen**.<!-- excerpt end -->

Let's create two functions. One which sums up and other squares up itself.

```java
Function<Integer, Integer> sum = x -> x + x;
Function<Integer, Integer> square = y -> y * y;  
```

Next, let's combine them, using compose and andThen.

```java
Integer sumAndSquareResult = sum.compose(square).apply(3); // Returns 18
Integer squareAndSumResult = sum.andThen(square).apply(3); // Returns 36

System.out.println("sum.compose(square): " + sumAndSquareResult);
System.out.println("sum.andThen(square): " + squareAndSumResult);
```
```
18
36
```

The difference between **compose** and **andThen** is the order in which they execute the functions.

 - **compose** executes the parameter first (square) followed by the caller (sum)
 - **andThen** executes the caller first (sum) followed by the parameter (square)

Let's take it further and see how we can apply composition on `BiFunction` functional interfaces.

>**_Let's use [cars](https://github.com/codeaches/java-8-examples/blob/master/src/main/java/com/codeaches/java8/examples/Car.java) as our data set for examples below_**.

### **Cars Inventory:**

| Manufacturer | Model        | Year         | Price        |
|:-------------|:-------------|:-------------|:-------------|
| Toyota       | Corolla      | 2013         | 21000.00 $   |
| Toyota       | Camry        | 2018         | 24000.00 $   |
| Mercedes     | Benz         | 2019         | 40000.00 $   |

<br>
Let's start by introducing a basic function - **byManufacturer** that filters cars based on Manufacturer.

```java
BiFunction<String, List<Car>, List<Car>> byManufacturer =
        (manufacturer, cars) -> cars.stream()
            .filter(car -> car.getManufacturer().equals(manufacturer))
            .collect(Collectors.toList());
```

**byManufacturer** is a BiFunction. They take two arguments.

Let's also create few basic functions that sorts a list of cars from costliest to cheapest(affordable I must say!) price and a function that returns the top most car in a list.

```java
Comparator<Car> carPriceComparator = 
                    (car1, car2) -> Double.compare(car2.getPrice(),car1.getPrice());

Function<List<Car>, List<Car>> sortByPrice = 
        cars -> cars.stream()
            .sorted(carPriceComparator)
            .collect(Collectors.toList());

Function<List<Car>, Optional<Car>> first = cars -> cars.stream().findFirst();
```

Now that we have few functions built, let's see how we can use them to compose new functions.

### **The Most Expensive Car**

We can find the most expensive car in our inventroy by sorting the cars by price and then taking the top one from the sorted list.

```java
Function<List<Car>, Optional<Car>> costliest = first.compose(sortByPrice);
Optional<Car> costliestCar = costliest.apply(cars);

System.out.println(costliestCar.isPresent() ? costliestCar.get() : null);
```
```
Car [manufacturer=Mercedes, model=Benz, year=2019, price=40000.0]
```

### **The Most Expensive Car By Toyota**
	
Let's see how to get the most expensive car by Toyota in our cars inventroy.

In our previous example, we wrote a function to get us the most expensive car. We can use this function in composition with a filter functions which gives all the cars based on car type to achieve this..

```java
BiFunction<String, List<Car>, Optional<Car>> highestByCarType = byManufacturer.andThen(costliest);
Optional<Car> costliestToyotaCar = highestByCarType.apply("Toyota", cars);

System.out.println(costliestToyotaCar.isPresent() ? costliestToyotaCar.get() : null);
```
```
Car [manufacturer=Toyota, model=Camry, year=2018, price=24000.0]
```

_Above are few examples of functional interfaces and functional compositions. The use cases around composition of functions are endless and can be customised for our needs._

**Your feedback is always appreciated. Happy coding!**
