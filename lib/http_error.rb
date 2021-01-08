# frozen_string_literal: true

module Abt
  module HttpError
    class HttpError < StandardError; end

    class BadRequestError < HttpError; end

    class UnauthorizedError < HttpError; end

    class ForbiddenError < HttpError; end

    class NotFoundError < HttpError; end

    class MethodNotAllowedError < HttpError; end

    class UnsupportedMediaTypeError < HttpError; end

    class ProcessingError < HttpError; end

    class TooManyRequestsError < HttpError; end

    class InternalServerError < HttpError; end

    class NotImplementedError < HttpError; end

    class UnknownError < HttpError; end

    def self.error_class_for_status(status) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      case status
      when 400 then BadRequestError
      when 401 then UnauthorizedError
      when 403 then ForbiddenError
      when 404 then NotFoundError
      when 405 then MethodNotAllowedError
      when 415 then UnsupportedMediaTypeError
      when 422 then ProcessingError
      when 429 then TooManyRequestsError
      when 500 then InternalServerError
      when 501 then NotImplementedError
      else UnknownError
      end
    end
  end
end
