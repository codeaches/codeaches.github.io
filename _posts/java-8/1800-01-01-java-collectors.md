---
layout: post

title:  "Collectors in Java"
description: "Collectors in Java"

permalink: "/java/collectors"

date: "2020-01-01"
last_modified_at: "2020-01-01"

categories: [Java]

github:
  repository_url: https://github.com/codeaches/java-8-examples
  badges: [download]
---

In this article let's go through different ways of accumulating the elements of a **Stream** using **Collectors**. This can be achived by using the **collect** method of  Stream interface. **collect** takes a Collector, which is an interface for reduction operations.<!-- excerpt end -->

>**_Let's use [cars](https://github.com/codeaches/java-8-examples/blob/master/src/main/java/com/codeaches/java8/examples/Car.java) as our data set for examples below_**.

### **Cars Inventory:**
{: .no_toc }

| Manufacturer | Model        | Year         | Price        |
|:-------------|:-------------|:-------------|:-------------|
| Toyota       | Corolla      | 2013         | 21000.00 $   |
| Toyota       | Camry        | 2018         | 24000.00 $   |
| Mercedes     | Benz         | 2019         | 40000.00 $   |

<br>

## Table of contents
{: .no_toc }

1. TOC
{:toc}

### **Filtering a Stream**

Let's get all the **Toyota cCars** in our inventory using the filter method and collect the filtered cars using **Collectors.toList**. This is pretty basic.

```java
List<Car> toyotaCars = cars.stream()
                .filter(car -> car.getManufacturer().equals("Toyota"))
                .collect(Collectors.toList());
```
```
[Car [manufacturer=Toyota, model=Corolla, year=2013, price=21000.0], 
Car [manufacturer=Toyota, model=Camry, year=2018, price=24000.0]]
```

That was simple! We used **Collectors.toList** which returns a collector that is sent to the collect method.

### **Converting a Stream to a Map**

Now, let's create a map with _model_ as the key and _Car_ as the value.

```java
Map<String, Car> carMap = cars.stream()
                .collect(Collectors.toMap(Car::getModel, Function.identity()));
```
```
{
    Benz=Car [manufacturer=Mercedes, model=Benz, year=2019, price=40000.0], 
    Camry=Car [manufacturer=Toyota, model=Camry, year=2018, price=24000.0], 
    Corolla=Car [manufacturer=Toyota, model=Corolla, year=2013, price=21000.0]
}
```

Here, we used **Collectors.toMap** which takes method for creating the keys and a function for creating the values. In our example we used _Car::getModel_ to say that we want the _model_ as the keys.

For the value mapping, we used **Function.identity**. This simply returns a function that always returns its input parameter — in our case the Car — as output.

### **Calculating averages**

Let’s look at calculating the averages.

Let's get an average price of a car in our inventory. We can achive this using **Collectors.averagingInt**

```java
Double averagePrice = cars.stream().collect(Collectors.averagingDouble(Car::getPrice));
```
```
28333.333333333332
```

>This arithmetic collector exists for int and long as well.

### **Calculating sum**

If we want to get total price of all of my cars in inventroy, we can use **Collectors.summingDouble**

```java
Double totalPrice = cars.stream().collect(Collectors.summingDouble(Car::getPrice));
```
```
85000.0
```

>This arithmetic collector exists for int and long as well.

### **Calculating sum across each group**

If we want to get total price for each of the manufacturer of our cars in inventroy, we can use **Collectors.groupingBy** and sum the balances using **Collectors.summingDouble**

```java
Map<String, Double> totalPriceByManufacturer = cars.stream()
        .collect(Collectors.groupingBy(Car::getManufacturer, Collectors.summingDouble(Car::getPrice)));
```
```
{Toyota=45000.0, Mercedes=40000.0}
```

### **Get costliest and cheapest car**

Let's say I want to get the costliest car. This can be achieved by using **Collectors.maxBy** which takes Comparator as it's input argument.

Let's define a **Comparator** which determines the car with highest price. We shall use this comparator in **Collectors.maxBy**

```java
Comparator<Car> costliestCarComparator = (car1, car2) -> Double.compare(car1.getPrice(),
				car2.getPrice());

Optional<Car> costliestCar = cars.stream().collect(Collectors.maxBy(costliestCarComparator));
```
```
Car [manufacturer=Mercedes, model=Benz, year=2019, price=40000.0]
```

Similarly, cheapest car can be found by using **Collectors.minBy**

```java
Optional<Car> cheapestCar = cars.stream().collect(Collectors.minBy(costliestCarComparator));
```
```
Car [manufacturer=Toyota, model=Corolla, year=2013, price=21000.0]
```

### **Joining the values**

Let's say I want a comma seperated _models_ of all the cars. This can be achieved by **Collectors.joining**

```java
String models = accounts.stream().map(Account::getAccountNumber).collect(Collectors.joining(", "));
```
```
Corolla, Camry, Benz
```

### **Stream partitioning based on a condition**

Let's say I want list of cars based on _Manufacturer_. 

This can be achieved by combination of **Predicate** and **Collectors.partitioningBy** methods.

```java
Predicate<Car> manufacturerPredicate = car -> car.getManufacturer().equals("Toyota");

Map<Boolean, List<Car>> mapyByManufacturer = cars.stream()
                .collect(Collectors.partitioningBy(manufacturerPredicate));
```
```
{
    false=[
           Car [manufacturer=Mercedes, model=Benz, year=2019, price=40000.0]
          ], 
    true=[
           Car [manufacturer=Toyota, model=Corolla, year=2013, price=21000.0], 
           Car [manufacturer=Toyota, model=Camry, year=2018, price=24000.0]
         ]
}
```

This will result in a map with two entries.

- One with key **true** which contains the cars that satisfied the _toyota_ car predicate.
- One with key **false** which contains the cars that did not satisfy the _toyota_ car predicate.

This concludes the features of **Collectors** class. I hope you like this aticle.

**Your feedback is always appreciated. Happy coding!**
