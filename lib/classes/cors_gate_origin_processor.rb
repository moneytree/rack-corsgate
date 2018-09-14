module Rack
  # CorsGateOriginProcessor allows:
  # - referer header to be transformed to Origin header
  # - removal of "Origin: null" (Chrome)

  class CorsGateOriginProcessor
    def initialize(app, opts = {})
      @app = app
      @remove_null_origin = opts[:remove_null_origin] || false
    end

    def call(env)
      if @remove_null_origin
        # Consider Chrome's "null" origin the same as no origin being set at all

        env.delete('HTTP_ORIGIN') if env['HTTP_ORIGIN'] == 'null'
        env.delete('HTTP_X_ORIGIN') if env['HTTP_X_ORIGIN'] == 'null'
      end

      # Use referer header if no origin-header is present

      origin = env['HTTP_X_ORIGIN'] || env['HTTP_ORIGIN']
      referer = env['HTTP_REFERER']

      if origin.nil? && referer
        env['HTTP_ORIGIN'] = referer_to_origin(referer)
      end

      @app.call(env)
    end

    private

    def referer_to_origin(referer)
      uri = URI(referer)

      if is_standard_port(uri)
        "#{uri.scheme}://#{uri.host}"
      else
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end
    end

    def is_standard_port(uri)
      return true if uri.scheme == 'https' && uri.port == 443
      return true if uri.scheme == 'http' && uri.port == 80
      false
    end
  end
end
