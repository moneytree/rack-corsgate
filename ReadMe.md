# Rack CorsGate middleware

Inspired by [CorsGate](https://github.com/mixmaxhq/cors-gate) as introduced by Mixmax, this Gem implements the same
CSRF-protection for Rack. In short, we use `Rack::Cors` to configure whether or not requests are allowed to occur, and
we enforce them via this middleware. Requests that are potential threats are blocked with a `403` response. Please read
[Using CORS policies to implement CSRF protection](https://mixmax.com/blog/modern-csrf) for the philosophy behind this
middleware.

## Installation

Install the gem:

`gem install rack-corsgate`

Or in your Gemfile:

```ruby
gem 'rack-corsgate'
```

## Configuration

CorsGate is actually two middleware functions:
 
- The `CorsGateOriginProcessor` middleware checks if we have an origin header. If we don't, it will try to determine the
  origin based on the `Referer` header. This middleware should be triggered *before* `Rack::Cors`.
- The `CorsGate` middleware enforces the result of the CORS test on the request, by actively blocking requests that are
  potential CSRF-attacks. This middleware should be triggered *after* `Rack::Cors`.

The easiest way to sandwich Rack::Cors with these two middlewares is as follows:

```ruby
# Rack::CorsGate.use middleware, opts = {}, &forbidden_handler
Rack::CorsGate.use config.middleware
```

This is essentially a shortcut for the following:

```ruby
config.middleware.insert_before Rack::Cors, Rack::CorsGateOriginProcessor
config.middleware.insert_after Rack::Cors, Rack::CorsGate
```

The options hash passed to `Rack::CorsGate.use` is passed on to both middlewares. The block applies to `Rack::CorsGate`
only (see API below).

**API**

```ruby
config.middleware.insert_before Rack::Cors, Rack::CorsGateOriginProcessor, { remove_null_origin: false }
```

*Options:*

- `remove_null_origin` (boolean, default: false): Treats `null` (string) origin headers as if no origin header was set.

```ruby
config.middleware.insert_after Rack::Cors, Rack::CorsGate, { simulation: false, strict: true, allow_safe: true } do |env, origin, method|
  # env: https://www.rubydoc.info/github/rack/rack/master/file/SPEC#label-The+Environment

  Rails.logger.warn("Blocked #{method} request from origin #{origin} to #{env['PATH_INFO']}")
end
```

*Options:*

- `simulation` (boolean, default: false): Allows potential attacks to be carried out as if the middleware wasn't there.
  This can be useful during implementation trials and tests (see also the block signature below).
- `strict` (boolean, default: false): If true, requires an origin to be present on all requests.
- `allow_safe` (boolean, default: false): If true, allows `GET` and `HEAD` requests without an origin.

Block `|env, origin, method|`:

This optional block gets invoked whenever a request is about to be rejected (even in simulation mode).

## License

MIT
