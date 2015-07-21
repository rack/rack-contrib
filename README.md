# Contributed Rack Middleware and Utilities

This package includes a variety of add-on components for Rack, a Ruby web server
interface:

* `Rack::AcceptFormat` - Adds a format extension at the end of the URI when there is none, corresponding to the mime-type given in the Accept HTTP header.
* `Rack::Access` - Limits access based on IP address
* `Rack::Backstage` - Returns content of specified file if it exists, which makes it convenient for putting up maintenance pages.
* `Rack::CSSHTTPRequest` - Adds CSSHTTPRequest support by encoding responses as CSS for cross-site AJAX-style data loading
* `Rack::Callbacks` - Implements DSL for pure before/after filter like Middlewares.
* `Rack::Config` - Shared configuration for cooperative middleware.
* `Rack::Cookies` - Adds simple cookie jar hash to env
* `Rack::Deflect` - Helps protect against DoS attacks.
* `Rack::Evil` - Lets the rack application return a response to the client from any place.
* `Rack::HostMeta` - Configures `/host-meta` using a block
* `Rack::JSONP` - Adds JSON-P support by stripping out the callback param and padding the response with the appropriate callback format.
* `Rack::LazyConditionalGet` - Caches a global `Last-Modified` date and updates it each time there is a request that is not `GET` or `HEAD`.
* `Rack::LighttpdScriptNameFix` - Fixes how lighttpd sets the `SCRIPT_NAME` and `PATH_INFO` variables in certain configurations.
* `Rack::Locale` - Detects the client locale using the Accept-Language request header and sets a `rack.locale` variable in the environment.
* `Rack::MailExceptions` - Rescues exceptions raised from the app and sends a useful email with the exception, stacktrace, and contents of the environment.
* `Rack::NestedParams` - parses form params with subscripts (e.g., * "`post[title]=Hello`") into a nested/recursive Hash structure (based on Rails' implementation).
* `Rack::NotFound` - A default 404 application.
* `Rack::PostBodyContentTypeParser` - Adds support for JSON request bodies. The Rack parameter hash is populated by deserializing the JSON data provided in the request body when the Content-Type is application/json.
* `Rack::Printout` - Prints the environment and the response per request
* `Rack::ProcTitle` - Displays request information in process title (`$0`) for monitoring/inspection with ps(1).
* `Rack::Profiler` - Uses ruby-prof to measure request time.
* `Rack::RelativeRedirect` - Transforms relative paths in redirects to absolute URLs.
* `Rack::ResponseCache` - Caches responses to requests without query strings to Disk or a user provider Ruby object. Similar to Rails' page caching.
* `Rack::ResponseHeaders` - Manipulates response headers object at runtime
* `Rack::Sendfile` - Enables `X-Sendfile` support for bodies that can be served from file.
* `Rack::Signals` - Installs signal handlers that are safely processed after a request
* `Rack::SimpleEndpoint` - Creates simple endpoints with routing rules, similar to Sinatra actions
* `Rack::StaticCache` - Modifies the response headers to facilitiate client and proxy caching for static files that minimizes http requests and improves overall load times for second time visitors.
* `Rack::TimeZone` - Detects the client's timezone using JavaScript and sets a variable in Rack's environment with the offset from UTC.
* `Rack::TryStatic` - Tries to match request to a static file

### Use

Git is the quickest way to the rack-contrib sources:

    git clone git://github.com/rack/rack-contrib.git

Gems are available too:

    gem install rack-contrib

Requiring `'rack/contrib'` will add autoloads to the Rack modules for all of the
components included. The following example shows what a simple rackup
(`config.ru`) file might look like:

```ruby
require 'rack'
require 'rack/contrib'

use Rack::Profiler if ENV['RACK_ENV'] == 'development'

use Rack::ETag
use Rack::MailExceptions

run theapp
```

### Testing

To contribute to the project, begin by cloning the repo and installing the necessary gems:

    gem install json rack ruby-prof test-spec test-unit

To run the entire test suite, run 

    rake test

To run a specific component's tests run

    specrb -Ilib:test -w test/spec_rack_thecomponent.rb

This works on ruby 1.8.7 but has problems under ruby 1.9.x. 

TODO: instructions for 1.9.x and include bundler

### Criteria for inclusion
The criteria for middleware being included in this project are roughly as follows:
* For patterns that are very common, provide a reference implementation so that other projects do not have to reinvent the wheel.
* For patterns that are very useful or interesting, provide a well-done implementation.
* The middleware fits in 1 code file and is relatively small. Currently all middleware in the project are < 150 LOC.
* The middleware doesn't have any dependencies other than rack and the ruby standard library.

These criteria were introduced several years after the start of the project, so some of the included middleware may not meet all of them. In particular, several middleware have external dependencies. It is possible that in some future release of rack-contrib, middleware with external depencies will be removed from the project.

When submitting code keep the above criteria in mind and also see the code
guidelines in CONTRIBUTING.md. 

### Links

* rack-contrib on GitHub:: <http://github.com/rack/rack-contrib>
* Rack:: <http://rack.rubyforge.org/>
* Rack On GitHub:: <http://github.com/rack/rack>
* rack-devel mailing list:: <http://groups.google.com/group/rack-devel>
* [![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/rack/rack-contrib?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
