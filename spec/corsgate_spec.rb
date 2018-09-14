# require 'rails/all'
require 'rack/cors'
require 'rack-corsgate'
require 'rack/test'

describe Rack::CorsGate do
  include Rack::Test::Methods

  @opts = {}
  @block = nil

  before(:each) do
    @opts = {}
    @block = nil
  end

  def success_response
    lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  end

  def app
    builder = Rack::Builder.new

    builder.use Rack::CorsGateOriginProcessor, @opts
    builder.use Rack::Cors do
      allow do
        origins 'valid-origin.com'
        resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
      end
    end

    builder.use Rack::CorsGate, @opts, &@block
    builder.run success_response
    builder.to_app
  end

  it 'can GET without origin, with strict: true, allow_safe: true' do
    @opts = { strict: true, allow_safe: true }

    get '/foo.json'

    expect(last_response.status).to be 200
  end

  it 'cannot GET without origin, with strict: true, allow_safe: false' do
    @opts = { strict: true, allow_safe: false }

    get '/foo.json'

    expect(last_response.status).to be 403
  end

  it 'cannot POST without origin, with strict: true, allow_safe: true' do
    @opts = { strict: true, allow_safe: true }

    post '/foo.json'

    expect(last_response.status).to be 403
  end

  it 'cannot POST without origin, with strict: true, allow_safe: false' do
    @opts = { strict: true, allow_safe: false }

    post '/foo.json'

    expect(last_response.status).to be 403
  end

  it 'can POST without origin, with strict: false' do
    @opts = { strict: false }

    post '/foo.json'

    expect(last_response.status).to be 200
  end

  it 'cannot GET from invalid origin, even with strict: false' do
    @opts = { strict: false }

    header 'Origin', 'invalid-origin.com'
    get '/foo.json'

    expect(last_response.status).to be 403
  end

  it 'can GET with "null" origin if we allow it, and with strict: true, allow_safe: true' do
    @opts = { remove_null_origin: true, strict: true, allow_safe: true }

    header 'Origin', 'null'
    get '/foo.json'

    expect(last_response.status).to be 200
  end

  it 'can GET with "null" origin if we allow it, and with strict: false' do
    @opts = { remove_null_origin: true, strict: false }

    header 'Origin', 'null'
    get '/foo.json'

    expect(last_response.status).to be 200
  end

  it 'cannot POST with "null" origin if we do not allow it, with strict: true' do
    @opts = { remove_null_origin: false, strict: true }

    header 'Origin', 'null'
    post '/foo.json'

    expect(last_response.status).to be 403
  end

  it 'cannot POST from invalid origin' do
    header 'Origin', 'invalid-origin.com'
    post '/foo.json'

    expect(last_response.status).to be 403
  end

  it 'cannot POST from invalid referer' do
    header 'Referer', 'https://invalid-origin.com/index.html'
    post '/foo.json'

    expect(last_response.status).to be 403
  end

  it 'can POST from invalid origin in simulation-mode' do
    @opts = { simulation: true }

    header 'Origin', 'invalid-origin.com'
    post '/foo.json'

    expect(last_response.status).to be 200
  end

  it 'can POST from invalid referer in simulation-mode' do
    @opts = { simulation: true }

    header 'Referer', 'https://invalid-origin.com/index.html'
    post '/foo.json'

    expect(last_response.status).to be 200
  end

  it 'invokes handler when it cannot POST from invalid origin' do
    called = 0
    @block = -> (env, origin, path) { called += 1 }

    header 'Origin', 'invalid-origin.com'
    post '/foo.json'
    expect(last_response.status).to be 403
    expect(called).to be 1
  end
end
