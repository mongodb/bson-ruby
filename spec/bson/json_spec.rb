require "spec_helper"

describe BSON::JSON do

  describe "#to_json" do

    let(:klass) do
      Class.new do
        include BSON::JSON

        def as_json(*args)
          { :test => "value" }
        end
      end
    end

    context "when provided no arguments" do

      let(:json) do
        klass.new.to_json
      end

      it "returns the object as json" do
        expect(json).to eq("{\"test\":\"value\"}")
      end
    end

    context "when provided arguments" do

      let(:json) do
        klass.new.to_json(:test)
      end

      it "returns the object as json" do
        expect(json).to eq("{\"test\":\"value\"}")
      end
    end
  end
end
