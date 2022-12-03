## hoon-misc

* `/gen/kids.hoon` - List all ships that you sponsor and have seen on the network, sorted by last contact time

## About `%say` Generators

Working with `%say` generators can be confusing since the sample type is complex.  Let's examine how input to a `%say` generator works, and see some examples of common patterns.

You should already be familiar with naked generators and working with hoon files on a development ship.  Read the official documentation on `%say` here: [Urbit Developers - %say Generators](https://developers.urbit.org/guides/core/hoon-school/J-stdlib-text#say-generators)

On your local ship, run `|mount %base` if you haven't already and create `<ship>/base/gen/hmmm.hoon`:

```hoon
:-  %say
|=  *
:-  %noun
~
```

Save the file and in dojo run `|commit %base` and then `+hmmm` to run the generator.

> :information_source: Repeat these commands for every example in this document

This first example does nothing, and should successfully just return `~`.

Because the sample type is `*` any noun, there will never be any input type errors.

### Troubleshooting Input

Let's change the sample type to something obviously wrong to produce an error:

```hoon
:-  %say
|=  @
:-  %noun
~
```

A sample of type `@` atom will always produce a type error, as the actual input is a cell:

```
dojo: generator failure
>   dojo: nest-need
@
>   dojo: nest-have
[ [ now=@da
    eny=@uvJ
    bec=[p=@p q=@tas r=?([%da p=@da] [%tas p=@tas] [%ud p=@ud])]
  ]
  %~
  %~
]
```

The `dojo: nest-have` section shows us what type of input is being passed in when we run `+hmmm`. It is a tuple with three items:

1. A nested tuple with a few things in it: `now`, `eny`, and `bec`
1. Nothing, represented by the null constant `%~`
1. Nothing, again `%~`

Getting familiar with these type errors is helpful for troubleshooting the sample type of your generator.

### Input Structure

What are these three things supposed to be?

The input to a `%say` generator is always a tuple containing three items:

1. Environment or context, itself a tuple containing:
    * `now` - the current time
    * `eny` - entropy, a random value
    * `bec` - the "beak", which is a tuple containing data about your ship as described here: [Path Prefix](https://developers.urbit.org/reference/glossary/path-prefix)
1. Unnamed Parameters, or positional arguments.  If specified, these are mandatory and must be in the correct order when running the generator.
1. Named Parameters, or keyword arguments.  These are optional even if specified and unordered.

In our previous example, both sets of parameters are `%~` empty because we simply ran `+hmmm` without including any parameters.

### Passing Parameters

Let's leave our generator as it is with the incorrect sample type `@`, and see how to pass parameters to a generator from the dojo.

Unnamed parameters are passed just by entering them after the generator name, similar to a typical command line program.  Run this in dojo:

```hoon
+hmmm 'hi' 10
```

This gives us an error with a different type than before:

```
dojo: generator failure
>   dojo: nest-need
@
>   dojo: nest-have
[ [ now=@da
    eny=@uvJ
    bec=[p=@p q=@tas r=?([%da p=@da] [%tas p=@tas] [%ud p=@ud])]
  ]
  [@t @ud %~]
  %~
]
```

Instead of the first `%~` that we had before, we now have `[@t @ud %~]`, which shows us our unnamed parameters are passed as a list.

Named parameters can be given after unnamed parameters using key-value pairs in the format `, =key val`:

```hoon
+hmmm 'hi' 10, =foo 11, =bar 12
```

If you have *only* named parameters, they follow directly after the generator name:

```hoon
+hmmm, =foo 11, =bar 12
```

Run either of those two examples, and you'll see a completely different error:

```
[%keyword-arg-failure {%bar %foo}]
```

We're getting this error because we're passing in keys that were not defined in the generator.  Since these parameters are named, optional, and unordered, they are handled differently than unnamed parameters.  We will accept this for now and look at named parameters again later on.

### Extracting Values

The type definition of a gate's sample has the powerful ability to destructure the sample and extract individual values out of it.  This allows us to concisely declare which values out of a large or complex type we are going to use and ignore the rest.

Let's go back to our first working example, then we will see how to modify it to return a random number.

```hoon
:-  %say
|=  *
:-  %noun
~
```

This sample type does not produce any errors because `*` is the most general type, but that also makes it useless for extracting a subvalue.

We know that the sample includes `eny`, a random number from our environment.  We need to replace the general type `*` with a more specific type that lets us pinpoint this `eny` value.

Using the `dojo: nest-have` section from our error earlier we know the sample is a tuple of three items, so we can start there:

```hoon
[* * *]
```

The first item is itself a tuple of three items:

```hoon
[[* * *] * *]
```

> :information_source: Technically, you could also say it's a tuple of five items, examine the structure of `bec` to see this.

`eny` is the second item in that nested tuple, and we can extract it by assigning it a face (also `eny`).  This allows us to refer to the value later in our code using `eny`.  We should also replace the general type `*` with its specific type `@uvJ`:

```hoon
[[* eny=@uvJ *] * *]
```

The last two items in the sample represent the two types of parameters, which we are not using in this example.  If left as `*` the program would accept unnamed parameters but ignore them.  We can forbid parameters and raise an error if they are provided by using `~` instead.  The complete example:

```hoon
:-  %say
|=  [[* eny=@uvJ *] ~ ~]
:-  %noun
eny
```

Run `+hmmm` and you should see a different random value each time.

### Positional Arguments

Unnamed parameters are specified by a list (null terminated tuple) of types, occupying the second position in the generator sample.  If we wanted a generator that ignores the environment data, but has two parameters `name` and `age`, it would look like this:

```hoon
:-  %say
|=  [* [name=@t age=@ud ~] ~]
:-  %noun
"Hello, {(trip name)} age {<age>}!"
```

Like in the previous examples, the parts of the sample we don't use (the 1st and 3rd items in this example) are denoted as any noun `*` to allow all values, or `~` to forbid any values.

This would be executed as:

```hoon
+hmmmm 'Billiam' 10
```

While the environment data is in a structure defined by the system which you must follow, the parameters for your generator are up to you.  When someone calls the generator they must pass all the arguments in order or receive a type error.  For example running this generator with a missing argument:

```hoon
+hmmm 'Albert'
```

would produce:

```hoon
dojo: generator failure
>   dojo: nest-need
[* [name=@t age=@ud %~] *]
>   dojo: nest-have
[ [ now=@da
    eny=@uvJ
    bec=[p=@p q=@tas r=?([%da p=@da] [%tas p=@tas] [%ud p=@ud])]
  ]
  [@t %~]
  *
]
```

The type passed `[@t %~]` does not match the type specified in the generator `[@t @ud %~]`.

### Keyword Arguments

Named parameters are specified the same way as unnamed parameters (as a list of types), except they appear as the third item in the sample.  A generator using only named parameters would look like this:

```hoon
:-  %say
|=  [* ~ [cat=@t dog=@t ~]]
:-  %noun
[cat dog]
```

Again we use `~` for the unnamed parameters, to forbid their use and raise an error if they are provided.

This example would be called as so:

```hoon
+hmmm, =dog 'Bud', =cat 'Cone'
```

These keyword arguments can be supplied in any order, or may be omitted.  Whenever a named argument is not given, the bunt value is supplied instead.  For example:

```hoon
+hmmm, =dog 'Bud'
```

would produce `['' 'Bud']`, where the parameter `cat` is the empty string `''` which is the bunt value of `@t`.

### Combining the Inputs

So far we've looked at the different parts of the `%say` generator sample in isolation, but of course they can be combined as needed for your application.

For one final example let's see them all being used together:

```hoon
:-  %say
|=  [[now=@da *] [name=@t age=@ud ~] [cat=@t dog=@t ~]]
:-  %noun
[now name age cat dog]
```
