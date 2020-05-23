# AnotherCombineCache

Collection of cache implementations to use with Combine framework

# ValueCache

ValueCache is used to cache a value produced from a given producer.
* While a value is produced, other value requesters will not trigger another produce action
* If the value don't exists or a error occurred the producer will be used to obtain the value/failure
* ValueCache is thread safe

```swift
let cache = ValueCache<Int, Never>(cacheName: "int") { () -> AnyPublisher<Int, Never> in
    // Return a value producer.
    // Ex: 
    return Future { promisse in
        queue.asyncAfter(deadline: .now() + 5) {
            promisse(Result.success(1))
        }
    }.eraseToAnyPublisher()
}))

// First value call will trigger the producer
cache.value().sinkIntoResultAndStore(in: &cancellables) { 
    // Handle the result
}

// Second call will wait for the producer to end or will use the cached value
// if the value is already available
cache.value().sinkIntoResultAndStore(in: &cancellables) { 
    // Handle the result
}        
```

## MultipleValuesCache

MultipleValuesCache is used to cache a single value for a given key produced from a given producer
* MultipleValuesCache can have multiple keys, but only a value for a key
* While a value is produced, other value requesters will not trigger another produce action for a given key
* If the value don't exists or a error occurred the producer will be used to obtain the value/failure
* MultipleValuesCache is thread safe

```swift
// URL is the key and the cached value is [Any]
let cache = MultipleValuesCache<URL, [Any], Error> { url -> AnyPublisher<[Any], Error> in
    return network.request(url)
}

// First value call will trigger the producer
cache.value(for: soupUrl).sinkIntoResultAndStore(in: &cancellables) { 
    // Handle the result
}

// Second call will wait for the producer to end or will use the cached value
// if the value is already available
cache.value(for: soupUrl).sinkIntoResultAndStore(in: &cancellables) { 
    // Handle the result
}     

// We can also fetch other values
// First value call will trigger the producer
cache.value(for: otherUrl).sinkIntoResultAndStore(in: &cancellables) { 
    // Handle the result
} 
```

# Roadmap
- [ ] MultipleValuesCache: Use NSCache or implement didReceiveMemoryWarningNotification?
- [ ] Unit tests
- [ ] More documentation
- [ ] Study more about the Publisher to try to transform the caches into a Publisher type

# Dependencies
* [AnotherSwiftCommonLib](https://github.com/rexcosta/AnotherSwiftCommonLib)
