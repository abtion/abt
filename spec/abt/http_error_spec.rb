# frozen_string_literal: true

RSpec.describe Abt::HttpError do
  describe "error_class_for_status" do
    context "when status is 400" do
      it "returns BadRequestError" do
        error_class = Abt::HttpError.error_class_for_status(400)
        expect(error_class).to be(Abt::HttpError::BadRequestError)
      end
    end

    context "when status is 401" do
      it "returns UnauthorizedError" do
        error_class = Abt::HttpError.error_class_for_status(401)
        expect(error_class).to be(Abt::HttpError::UnauthorizedError)
      end
    end

    context "when status is 403" do
      it "returns ForbiddenError" do
        error_class = Abt::HttpError.error_class_for_status(403)
        expect(error_class).to be(Abt::HttpError::ForbiddenError)
      end
    end

    context "when status is 404" do
      it "returns NotFoundError" do
        error_class = Abt::HttpError.error_class_for_status(404)
        expect(error_class).to be(Abt::HttpError::NotFoundError)
      end
    end

    context "when status is 405" do
      it "returns MethodNotAllowedError" do
        error_class = Abt::HttpError.error_class_for_status(405)
        expect(error_class).to be(Abt::HttpError::MethodNotAllowedError)
      end
    end

    context "when status is 415" do
      it "returns UnsupportedMediaTypeError" do
        error_class = Abt::HttpError.error_class_for_status(415)
        expect(error_class).to be(Abt::HttpError::UnsupportedMediaTypeError)
      end
    end

    context "when status is 422" do
      it "returns ProcessingError" do
        error_class = Abt::HttpError.error_class_for_status(422)
        expect(error_class).to be(Abt::HttpError::ProcessingError)
      end
    end

    context "when status is 429" do
      it "returns TooManyRequestsError" do
        error_class = Abt::HttpError.error_class_for_status(429)
        expect(error_class).to be(Abt::HttpError::TooManyRequestsError)
      end
    end

    context "when status is 500" do
      it "returns InternalServerError" do
        error_class = Abt::HttpError.error_class_for_status(500)
        expect(error_class).to be(Abt::HttpError::InternalServerError)
      end
    end

    context "when status is 501" do
      it "returns NotImplementedError" do
        error_class = Abt::HttpError.error_class_for_status(501)
        expect(error_class).to be(Abt::HttpError::NotImplementedError)
      end
    end

    context "when status doesn't match an error type" do
      it "returns UnknownError" do
        error_class = Abt::HttpError.error_class_for_status(999)
        expect(error_class).to be(Abt::HttpError::UnknownError)
      end
    end
  end
end
