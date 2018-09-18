# require 'rails/all'
require 'rack/cors'
require 'rack-corsgate'
require 'rack/test'

describe Rack::CorsGate do
  include Rack::Test::Methods

  before(:each) do
    @middleware_opts = {}
    @block = nil
  end

  def success_response
    lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  end

  def app
    builder = Rack::Builder.new

    builder.use Rack::CorsGateOriginProcessor, @middleware_opts
    builder.use Rack::Cors do
      allow do
        origins 'https://valid-origin.com'
        resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
      end
    end

    builder.use Rack::CorsGate, @middleware_opts, &@block
    builder.run success_response
    builder.to_app
  end

  def req(method, origin, referer, opts, expected_status)
    @middleware_opts = opts

    header 'Origin', origin unless origin.nil?
    header 'Referer', referer unless referer.nil?

    case method
    when 'GET'
      get '/foo.json'
    when 'POST'
      post '/foo.json'
    else
      throw :bad_method, method
    end

    expect(last_response.status).to eq expected_status
  end

  describe 'strict: false, allow_safe: true' do
    opts = { strict: false, allow_safe: true }

    it 'can GET without origin' do
      req('GET', nil, nil, opts, 200)
    end

    it 'can GET with valid origin' do
      req('GET', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can GET with valid referer' do
      req('GET', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'can GET with invalid origin' do
      req('GET', 'https://invalid-origin.com', nil, opts, 200)
    end

    it 'can POST without origin' do
      req('POST', nil, nil, opts, 200)
    end

    it 'can POST with valid origin' do
      req('POST', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can POST with valid referer' do
      req('POST', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'cannot POST with invalid origin' do
      req('POST', 'https://invalid-origin.com', nil, opts, 403)
    end
  end

  describe 'strict: false, allow_safe: false' do
    opts = { strict: false, allow_safe: false }

    it 'can GET without origin' do
      req('GET', nil, nil, opts, 200)
    end

    it 'can GET with valid origin' do
      req('GET', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can GET with valid referer' do
      req('GET', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'cannot GET with invalid origin' do
      req('GET', 'https://invalid-origin.com', nil, opts, 403)
    end

    it 'can POST without origin' do
      req('POST', nil, nil, opts, 200)
    end

    it 'can POST with valid origin' do
      req('POST', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can POST with valid referer' do
      req('POST', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'cannot POST with invalid origin' do
      req('POST', 'https://invalid-origin.com', nil, opts, 403)
    end
  end

  describe 'strict: true, allow_safe: true' do
    opts = { strict: true, allow_safe: true }

    it 'can GET without origin' do
      req('GET', nil, nil, opts, 200)
    end

    it 'can GET with valid origin' do
      req('GET', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can GET with valid referer' do
      req('GET', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'can GET with invalid origin' do
      req('GET', 'https://invalid-origin.com', nil, opts, 200)
    end

    it 'cannot POST without origin' do
      req('POST', nil, nil, opts, 403)
    end

    it 'can POST with valid origin' do
      req('POST', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can POST with valid referer' do
      req('POST', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'cannot POST with invalid origin' do
      req('POST', 'https://invalid-origin.com', nil, opts, 403)
    end
  end

  describe 'strict: true, allow_safe: false' do
    opts = { strict: true, allow_safe: false }

    it 'cannot GET without origin' do
      req('GET', nil, nil, opts, 403)
    end

    it 'can GET with valid origin' do
      req('GET', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can GET with valid referer' do
      req('GET', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'cannot GET with invalid origin' do
      req('GET', 'https://invalid-origin.com', nil, opts, 403)
    end

    it 'cannot POST without origin' do
      req('POST', nil, nil, opts, 403)
    end

    it 'can POST with valid origin' do
      req('POST', 'https://valid-origin.com', nil, opts, 200)
    end

    it 'can POST with valid referer' do
      req('POST', nil, 'https://valid-origin.com/foo', opts, 200)
    end

    it 'cannot POST with invalid origin' do
      req('POST', 'https://invalid-origin.com', nil, opts, 403)
    end
  end

  describe 'remove_null_origin: true' do
    it 'can GET with "null" origin and strict: true, allow_safe: true' do
      opts = { remove_null_origin: true, strict: true, allow_safe: true }

      req('GET', 'null', nil, opts, 200)
    end

    it 'cannot GET with "null" origin and strict: true, allow_safe: false' do
      opts = { remove_null_origin: true, strict: true, allow_safe: false }

      req('GET', 'null', nil, opts, 403)
    end

    it 'cannot POST with "null" origin and strict: true, allow_safe: true' do
      opts = { remove_null_origin: true, strict: true, allow_safe: true }

      req('POST', 'null', nil, opts, 403)
    end
  end

  describe 'remove_null_origin: false' do
    it 'can GET with "null" origin and strict: true, allow_safe: true' do
      opts = { remove_null_origin: false, strict: true, allow_safe: true }

      req('GET', 'null', nil, opts, 200)
    end

    it 'cannot GET with "null" origin and strict: true, allow_safe: false' do
      opts = { remove_null_origin: false, strict: true, allow_safe: false }

      req('GET', 'null', nil, opts, 403)
    end

    it 'cannot POST with "null" origin and strict: true, allow_safe: true' do
      opts = { remove_null_origin: false, strict: true, allow_safe: true }

      req('POST', 'null', nil, opts, 403)
    end
  end

  describe 'simulation-mode' do
    opts = { simulation: true }

    it 'can POST from invalid origin in simulation-mode' do
      req('POST', 'https://invalid-origin.com', nil, opts, 200)
    end

    it 'can POST from invalid referer in simulation-mode' do
      req('POST', nil, 'https://invalid-origin.com/foo', opts, 200)
    end
  end

  describe 'failure-handler' do
    it 'invokes handler block when rejecting' do
      opts = {}
      called = 0
      @block = -> (env, origin, path) { called += 1 }

      req('POST', 'https://invalid-origin.com', nil, opts, 403)
      expect(called).to be 1
    end

    it 'invokes handler block when rejecting in simulation mode (despite 200)' do
      opts = { simulation: true }
      called = 0
      @block = -> (env, origin, path) { called += 1 }

      req('POST', 'https://invalid-origin.com', nil, opts, 200)
      expect(called).to be 1
    end
  end
end
