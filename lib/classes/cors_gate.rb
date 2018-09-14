require_relative './cors_gate_origin_processor.rb'

module Rack
  class CorsGate
    def initialize(app, opts = {}, &forbidden_handler)
      @app = app

      @simulation = opts[:simulation] || false
      @strict = opts[:strict] || false
      @allow_safe = opts[:allow_safe] || false
      @forbidden_handler = forbidden_handler
    end

    def call(env)
      origin = env['HTTP_X_ORIGIN'] || env['HTTP_ORIGIN']
      method = env['REQUEST_METHOD']

      if is_allowed(env, origin, method)
        # valid request
        @app.call(env)
      else
        # allow logging, etc
        @forbidden_handler.call(env, origin, method) if @forbidden_handler

        # if we're simulating, forbidden_handler will have been called, but we continue with app-execution
        return @app.call(env) if @simulation

        # 403 Forbidden
        [403, {}, []]
      end
    end

    def self.use(middleware, opts = {}, &forbidden_handler)
      middleware.insert_before Rack::Cors, Rack::CorsGateOriginProcessor, opts
      middleware.insert_after Rack::Cors, Rack::CorsGate, opts, &forbidden_handler
    end

    private

    def is_allowed(env, origin, method)
      # if strict, require an Origin header
      if origin.nil?
        return true unless @strict

        # if strict, but allow_safe we let GET and HEAD through
        if @allow_safe && ['GET', 'HEAD'].include?(method)
          return true
        end
        return false
      end

      env['rack.cors'].hit?
    end
  end
end
