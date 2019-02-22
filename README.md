# Ratatouille

[![Hex.pm](https://img.shields.io/hexpm/v/ratatouille.svg)](https://hex.pm/packages/ratatouille)
[![Hexdocs.pm](https://img.shields.io/badge/api-hexdocs-brightgreen.svg)](https://hexdocs.pm/ratatouille)

Ratatouille is a declarative terminal UI kit for Elixir for building rich
text-based terminal applications similar to how you write HTML.

It builds on top of the [termbox][termbox] API (using the Elixir bindings from
[ex_termbox][ex_termbox].

For the API Reference, see: [https://hexdocs.pm/ratatouille](https://hexdocs.pm/ratatouille).

![Toby][toby_screenshot]
*[Toby](https://github.com/ndreynolds/toby), a terminal-based Erlang observer built with Ratatouille*

[termbox]: https://github.com/nsf/termbox
[ex_termbox]: https://github.com/ndreynolds/ex_termbox
[toby_screenshot]: https://github.com/ndreynolds/ratatouille/raw/master/doc/toby.png

**Table of Contents**

* [Ratatouille](#ratatouille)
  * [Getting Started](#getting-started)
    * [Building an Application](#building-an-application)
      * [init/1](#init1)
      * [update/2](#update2)
      * [render/1](#render1)
      * [Running it](#running-it)
  * [Views](#views)
  * [Examples](#examples)
  * [Under the Hood](#under-the-hood)
  * [Packaging and Distributing](#packaging-and-distributing)
    * [Defining an OTP Application](#defining-an-otp-application)
    * [Distillery Releases](#distillery-releases)
  * [Installation](#installation)
    * [From Hex](#from-hex)
    * [From Source](#from-source)
  * [Roadmap](#roadmap)
  * [Contributing](#contributing)
    * [Running the Tests](#running-the-tests)

## Getting Started

Ratatouille implements the Elm Architecture as a way to structure application
logic. This fits quite naturally in Elixir and is part of what makes Ratatouille
declarative. If you've already used it on the web, it should feel very familiar.

As with a GenServer definition, Ratatouille apps only implement a behaviour by
defining callbacks and don't know how to start or run themselves. It's the
application runtime handles all of those (sometimes tricky) details.

### Building an Application

Let's build a simple application that displays an integer counter which can be
incremented when the user presses "+" and decremented when the user presses "-".

First a quick clarification, since we're using the word "application" a lot. For
our purposes, an application is a terminal application, and not necessarily an
OTP application, but your terminal application could also be an OTP
application. We'll cover that in [Packaging and Distributing
Applications](#packaging-and-distributing) below.

Back to the counter app. First we'll look at the entire example, then we'll go
through it line by line to see what each line does. You can also find this
example [in the repo][counter_example] and run it with `mix run`.

[counter_example]: https://github.com/ndreynolds/ratatouille/blob/master/examples/counter.exs

```elixir
# examples/counter.exs

defmodule Counter do
  @behaviour Ratatouille.App

  import Ratatouille.View

  def init(_context), do: 0

  def update(model, msg) do
    case msg do
      {:event, %{ch: ?+}} -> model + 1
      {:event, %{ch: ?-}} -> model - 1
      _ -> model
    end
  end

  def render(model) do
    view do
      label(content: "Counter is #{model} (+/-)")
    end
  end
end

Ratatouille.run(Counter)
```

At the top, we define a new module (`Counter`) for the app and we inform Elixir
that it will implement the `Ratatouille.App` behaviour. This just ensures we're
warned if we forget to implement a callback and serves as documentation that
this is a Ratatouille app.

```elixir
defmodule Counter do
  @behaviour Ratatouille.App

  ...
end
```

Next, we import the View DSL from
[`Ratatouille.View`](https://hexdocs.pm/ratatouille/Ratatouille.View):

```elixir
import Ratatouille.View
```

The View DSL provides element builder functions like `view`, `row`, `table`,
`label` that you can use to define views. Think of them like HTML tags.

#### `init/1`

The `init/1` callback defines the initial model. "Model" is the Elm
architecture's term for what we often call "state" in Elixir/Erlang. As with a
GenServer, the state (our model) will later be passed to callbacks when things
happen in order to allow the app to update it.

The model can be any Erlang term. For larger apps, it's helpful to use maps or
structs. Here, we just have an integer counter, so we return `0`:

```elixir
defmodule Counter do
  ...

  def init(_context), do: 0

  ...
end
```

#### `update/2`

The `update/2` callback defines how to transform the model when a particular
message is received. Ratatouille's runtime will automatically call `update/2`
when terminal events occur (pressing a key, resizing the window, clicking the
mouse, etc.). We can also send ourselves messages via subscriptions and commands.

Here, we'd like to increment the counter when we get a `?+` key press and
decrement it when get a `?-`. Event messages are based on the underlying termbox
events and characters are given as code points (i.e., `?a` is `97`).

```elixir
defmodule Counter do
  ...

  def update(model, msg) do
    case msg do
      {:event, %{ch: ?+}} -> model + 1
      {:event, %{ch: ?-}} -> model - 1
      _ -> model
    end
  end

  ...
end
```

It's a good idea to provide a fallback clause in case we don't know how to
handle a message. This way the app won't crash if the user presses a key that
the app doesn't handle. But if things stop working as you expect, try removing
the fallback see if important messages are going unmatched.

#### `render/1`

The `render/1` callback defines a view to display the model. The runtime will
call it as needed when it needs to update the terminal window.

Similar to HTML, a view is defined as a tree of elements (nodes). Elements have
attributes (e.g., `text: bold`) and children (nested content). While helper
functions can return arbitrary element trees, the `render/1` callback must
return a view tree starting with a root `view` element---it's sort of like the
`<body>` tag in HTML.

```elixir
defmodule Counter do
  ...

  def render(model) do
    view do
      label(content: "Counter is #{model} (+/- to increment/decrement, q to quit)")
    end
  end

  ...
end
```

#### Running it

There's a final and very important line at the bottom:

```elixir
Ratatouille.run(Counter)
```

This starts the application runtime with our app definition. Options can be
passed as a second argument. This is an easy way to run simple apps. For more
complicated ones, it's recommended to define an OTP application.

That's it---now you can run the program with `mix run <file>`. To run the
bundled example:

```bash
$ mix run examples/counter.exs
```

You should see the counter we defined, be able to make changes to it with '+'
and '-', and be able to quit using 'q'.

## Views

| Element | Description       |
| ------- | ----------------- |
| [`bar`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#bar/0) | Block-level element for creating title, status or menu bars |
| [`chart`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#chart/0) | Element for plotting a series as a multi-line chart |
| [`column`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#column/0) | Container occupying a vertical segment of the grid |
| [`label`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#label/0) | Block-level element for displaying text |
| [`overlay`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#overlay/0) | Container overlaid on top of the view |
| [`panel`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#panel/0) | Container with a border and title used to demarcate content |
| [`row`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#row/0) | Container used to define grid layouts with one or more columns |
| [`sparkline`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#sparkline/0) | Element for plotting a series in a single line |
| [`table`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#table/0) | Container for displaying data in rows and columns |
| [`table_cell`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#table_cell/0) | Element representing a table cell |
| [`table_row`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#table_row/0) | Container representing a row of the table |
| [`text`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#text/0) | Inline element for displaying uniformly-styled text |
| [`tree`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#tree/0) | Container for displaying data as a tree of nodes |
| [`tree_node`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#tree_node/0) | Container representing a tree node |
| [`view`](https://hexdocs.pm/ratatouille/Ratatouille.View.html#view/0) | Top-level container |

## Examples

| Name | Description |
| ---- | ----------- |
| [`rendering.exs`](https://github.com/ndreynolds/ratatouille/tree/master/examples/rendering.exs) | A rendering demo of all the supported elements |
| [`counter.exs`](https://github.com/ndreynolds/ratatouille/tree/master/examples/counter.exs) | How to create a simple app with state and updates |
| [`editor.exs`](https://github.com/ndreynolds/ratatouille/tree/master/examples/editor.exs) | How to use receive and display user input |
| [`multiple_views.exs`](https://github.com/ndreynolds/ratatouille/tree/master/examples/multiple_views.exs) | How to render different views/tabs based on a selection |
| [`subscriptions.exs`](https://github.com/ndreynolds/ratatouille/tree/master/examples/subscriptions.exs) | How to subscribe to multiple intervals |
| [`commands.exs`](https://github.com/ndreynolds/ratatouille/tree/master/examples/commands.exs) | How to run commands asynchronously and receive the results |

## Under the Hood

The application runtime abstracts away a lot of the details concerning how the
terminal is actually updated and events are received. If you're interested in
how it actually works, see this guide:

<https://hexdocs.pm/ratatouille/doc/under-the-hood.html>

## Packaging and Distributing

*Warning: This part is still rough around the edges.*

While it's easy to run apps with `mix run`, packaging them for others to easily
run is a bit more complicated. Depending on the type of app you're building, it
might not be reasonable to assume that users have any Elixir or Erlang tools
installed. Terminal apps are usually distributed as binary executables so that
they can just be run as such without additional dependencies. Fortunately, this
is possible with Distillery.

### Defining an OTP Application

In order to use Distillery, we first define an OTP application that starts the
application runtime. `Ratatouille.Runtime.Supervisor` takes care of starting all
the necessary runtime components, so we start this supervisor under the OTP
application supervisor.

For example, the OTP application for toby looks like this:

```elixir
defmodule Toby do
  use Application

  def start(_type, _args) do
    children = [
      {Ratatouille.Runtime.Supervisor, runtime: [app: Toby.App]},
      # other workers...
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: Toby.Supervisor
    )
  end
end
```

### Distillery Releases

Follow the Distillery guide to generate a release configuration.

In order to make the release "batteries included", it's important that you have
`include_erts` set to `true`:

``` elixir
environment :prod do
  ...
  set(include_erts: true)
  ...
end
```

Now it's possible to create a distributable, self-contained executable with
Distillery. Releases built on a given architecture can generally be run on
machines of the same architecture.

```bash
MIX_ENV=prod mix release --executable --transient
```

This creates a Distillery release that bundles the Erlang runtime and the
application. Start it in the foreground, e.g.:

```bash
_build/prod/rel/toby/bin/toby.run foreground
```

You can also move this executable somewhere else (e.g., to a directory in your
$PATH). A current caveat is that it must be able to unpack itself, as Distillery
executables are self-extracting archives.

## Installation

### From Hex

Add Ratatouille as a dependency in your project's `mix.exs`:

```elixir
def deps do
  [
    {:ratatouille, "~> 0.4.0"}
  ]
end
```

### From Source

To try out the master branch, first clone the repo:

```bash
git clone https://github.com/ndreynolds/ratatouille.git
cd ratatouille
```

Next, fetch the deps:

```
mix deps.get
```

Finally, try out one of the included [`examples/`][examples]:

```
mix run examples/rendering.exs
```

If you see lots of things drawn on your terminal screen, you're good to go. Use
"q" to quit in the examples (unless otherwise specified).

[examples]: https://github.com/ndreynolds/ratatouille/blob/master/examples/

## Roadmap

* Apps
  * [x] Application Runtime
  * [x] Subscriptions
  * [x] Commands
* Views / Rendering
  * [x] Rendering engine with basic elements
  * [ ] More configurable charts (axis label, color, multiple lines, etc.)
  * [ ] Uniform support for text styling (incl. inheritance)
  * [ ] Automatic translation to termbox styling constants
    * For example, `color: :red` instead of `color: Constants.color(:red)`.
  * [ ] Rendering optimizations (view diffing, more efficient updates, etc.)
* Events
  * [ ] Translate termbox events to a cleaner format
    * Dealing with the integer constants is incovenient. These could be
      converted to atoms by the event manager.
* Terminal Backend
  * [x] ex_termbox NIFs
  * [ ] Alternative port-based termbox backend
* Customization
  * [ ] Registering custom element renderers
    * This would support using custom elements (e.g. `my_table()`) that are
      defined outside of the core library.

## Contributing

Contributions are much appreciated. They don't necessarily have to come in the
form of code, I'm also very thankful for bug reports, documentation
improvements, questions, and suggestions.

### Running the Tests

Run the unit tests as usual:

```
mix test
```

Ratatouille also includes integration tests of the bundled examples. These
aren't included in the default suite because they actually run the example apps.
The integration suite can be run like so:

```
mix test --only integration
```
