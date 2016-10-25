require 'spec_helper'

describe Regexp::Raw do


  describe "#as_json" do

    let(:object) do
      described_class.new(pattern, 'im')
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq(
                                    { "$regex" => "\\W+", "$options" => "im" }
                                )
    end

    it_behaves_like "a JSON serializable object"
  end

  let(:pattern) { '\W+' }
  let(:options) { '' }
  let(:bson) { "#{pattern}#{BSON::NULL_BYTE}#{options}#{BSON::NULL_BYTE}" }

  describe "#from_bson" do

    let(:obj) { Regexp.from_bson(io) }
    let(:io) { BSON::ByteBuffer.new(bson) }

    it "deserializes to a Regexp::Raw object" do
      expect(obj).to be_a(Regexp::Raw)
    end

    it "deserializes the pattern" do
      expect(obj.pattern).to eq(pattern)
    end

    context "when there are no options" do

      it "does not set any options on the raw regexp object" do
        expect(obj.options).to eq(options)
      end
    end

    context "when there are options" do

      context "when there is the i ignorecase option" do

        let(:options) { 'i' }

        it "deserializes the pattern" do
          expect(obj.pattern).to eq(pattern)
        end

        it "sets the i option on the raw regexp object" do
          expect(obj.options).to eq(options)
        end
      end

      context "when there is the l locale dependent option" do

        let(:options) { 'l' }

        it "deserializes the pattern" do
          expect(obj.pattern).to eq(pattern)
        end

        it "sets the l option on the raw regexp object" do
          expect(obj.options).to eq(options)
        end
      end

      context "when there is the m multiline option" do

        let(:options) { 'm' }

        it "deserializes the pattern" do
          expect(obj.pattern).to eq(pattern)
        end

        it "sets the m option on the raw regexp object" do
          expect(obj.options).to eq(options)
        end
      end

      context "when there is the s dotall option" do

        let(:options) { 's' }

        it "deserializes the pattern" do
          expect(obj.pattern).to eq(pattern)
        end

        it "sets the s option on the raw regexp object" do
          expect(obj.options).to eq(options)
        end
      end

      context "when there is the u match unicode option" do

        let(:options) { 'u' }

        it "deserializes the pattern" do
          expect(obj.pattern).to eq(pattern)
        end

        it "sets the u option on the raw regexp object" do
          expect(obj.options).to eq(options)
        end
      end

      context "when there is the x verbose option" do

        let(:options) { 'x' }

        it "deserializes the pattern" do
          expect(obj.pattern).to eq(pattern)
        end

        it "sets the x option on the raw regexp object" do
          expect(obj.options).to eq(options)
        end
      end

      context "when all options are set" do

        let(:options) { 'ilmsux' }

        it "deserializes the pattern" do
          expect(obj.pattern).to eq(pattern)
        end

        it "sets all options on the raw regexp object" do
          expect(obj.options).to eq(options)
        end
      end
    end
  end

  context "when a method is called on a Raw regexp object" do

    let(:obj) { Regexp.from_bson(io) }
    let(:io) { BSON::ByteBuffer.new(bson) }

    it "forwards the method call on to the compiled Ruby Regexp object" do
      expect(obj.source).to eq(pattern)
    end
  end

  context "#to_bson" do

    let(:obj) { Regexp::Raw.new(pattern, options) }
    let(:options) { '' }
    let(:bson) { "#{pattern}#{BSON::NULL_BYTE}#{options}#{BSON::NULL_BYTE}" }
    let(:serialized) { obj.to_bson.to_s }

    it "has the correct single byte BSON type" do
      expect(obj.bson_type).to eq(11.chr)
    end

    it "serializes the pattern" do
      expect(serialized).to eq(bson)
    end

    context "where there are no options" do

      it "does not set any options on the bson regex object" do
        expect(serialized).to eq(bson)
      end
    end

    context "when there are options" do

      context "when there is the i ignorecase option" do

        let(:options) { 'i' }

        it "sets the option on the serialized bson object" do
          expect(serialized).to eq(bson)
        end
      end

      context "when there is the l locale dependent option" do

        let(:options) { 'l' }

        it "sets the option on the serialized bson object" do
          expect(serialized).to eq(bson)
        end
      end

      context "when there is the m multiline option" do

        let(:options) { 'm' }

        it "sets the option on the serialized bson object" do
          expect(serialized).to eq(bson)
        end
      end

      context "when there is the s dotall option" do

        let(:options) { 's' }

        it "sets the option on the serialized bson object" do
          expect(serialized).to eq(bson)
        end
      end

      context "when there is the u match unicode option" do

        let(:options) { 'u' }

        it "sets the option on the serialized bson object" do
          expect(serialized).to eq(bson)
        end
      end

      context "when there is the x verbose option" do

        let(:options) { 'x' }

        it "sets the option on the serialized bson object" do
          expect(serialized).to eq(bson)
        end
      end

      context "when all options are set" do

        let(:options) { 'ilmsux' }

        it "sets all options on the serialized bson object" do
          expect(serialized).to eq(bson)
        end

        context "when the options are not provided in alphabetical order" do

          let(:options) { 'mislxu' }
          let(:bson) { "#{pattern}#{BSON::NULL_BYTE}ilmsux#{BSON::NULL_BYTE}" }

          it "serializes the options in alphabetical order" do
            expect(serialized).to eq(bson)
          end
        end
      end
    end
  end

  describe "#compile" do

    let(:obj) { Regexp.from_bson(io) }
    let(:io) { BSON::ByteBuffer.new(bson) }
    let(:ruby_regexp) { obj.compile }

    it "sets the pattern on the Ruby Regexp object" do
      expect(obj.pattern).to eq(ruby_regexp.source)
    end

    context "when there are no options set" do

      it "does not set any options on the Ruby Regexp object" do
        expect(ruby_regexp.options).to eq(0)
      end
    end

    context "when there are options set" do

      context "when there is the i ignorecase option" do

        let(:options) { 'i' }

        it "sets the i option on the Ruby Regexp object" do
          expect(ruby_regexp.options).to eq(::Regexp::IGNORECASE)
        end
      end

      context "when there is the l locale dependent option" do

        let(:options) { 'l' }

        it "does not set an option on the Ruby Regexp object" do
          expect(ruby_regexp.options).to eq(0)
        end
      end

      context "when there is the m multiline option" do

        let(:options) { 'm' }

        it "does not set an option on the Ruby Regexp object" do
          expect(ruby_regexp.options).to eq(0)
        end
      end

      context "when there is the s dotall option" do

        let(:options) { 's' }

        # s in a bson regex maps to a Ruby Multiline Regexp option
        it "sets the m option on the Ruby Regexp object" do
          expect(ruby_regexp.options).to eq(::Regexp::MULTILINE)
        end
      end

      context "when there is the u match unicode option" do

        let(:options) { 'm' }

        it "does not set an option on the Ruby Regexp object" do
          expect(ruby_regexp.options).to eq(0)
        end
      end

      context "when there is the x verbose option" do

        let(:options) { 'x' }

        it "sets the x option on the Ruby Regexp object" do
          expect(ruby_regexp.options).to eq(::Regexp::EXTENDED)
        end
      end

      context "when all options are set" do

        let(:options) { 'ilmsux' }

        # s in a bson regex maps to a Ruby Multiline Regexp option
        it "sets the i, m, and x options on the Ruby Regexp object" do
          expect(ruby_regexp.options).to eq(::Regexp::IGNORECASE | ::Regexp::MULTILINE | ::Regexp::EXTENDED)
        end
      end
    end
  end

  context "when a Regexp::Raw object is roundtripped" do

    let(:obj) { Regexp::Raw.new(pattern, options) }
    let(:serialized) { obj.to_bson.to_s }
    let(:roundtripped) { Regexp.from_bson(BSON::ByteBuffer.new(serialized)) }

    it "roundtrips the pattern" do
      expect(roundtripped.pattern).to eq(pattern)
    end

    context "when there are no options" do

      let(:options) { '' }

      it "does not set any options on the roundtripped Regexp::Raw object" do
        expect(roundtripped.options).to eq(options)
      end
    end

    context "when there are options set" do

      context "when there is the i ignorecase option" do

        let(:options) { 'i' }

        it "sets the i option on the roundtripped Regexp::Raw object" do
          expect(roundtripped.options).to eq(options)
        end
      end

      context "when there is the l locale dependent option" do

        let(:options) { 'l' }

        it "sets the l option on the roundtripped Regexp::Raw object" do
          expect(roundtripped.options).to eq(options)
        end
      end

      context "when there is the m multiline option" do

        let(:options) { 'm' }

        it "sets the m option on the roundtripped Regexp::Raw object" do
          expect(roundtripped.options).to eq(options)
        end
      end

      context "when there is the s dotall option" do

        let(:options) { 's' }

        it "sets the s option on the roundtripped Regexp::Raw object" do
          expect(roundtripped.options).to eq(options)
        end
      end

      context "when there is the u match unicode option" do

        let(:options) { 'u' }

        it "sets the u option on the roundtripped Regexp::Raw object" do
          expect(roundtripped.options).to eq(options)
        end
      end

      context "when there is the x verbose option" do

        let(:options) { 'x' }

        it "sets the x option on the roundtripped Regexp::Raw object" do
          expect(roundtripped.options).to eq(options)
        end
      end

      context "when all options are set" do

        let(:options) { 'ilmsux' }

        it "sets all the options on the roundtripped Regexp::Raw object" do
          expect(roundtripped.options).to eq(options)
        end

        context "when the options are passed in not in alphabetical order" do

          let(:options) { 'sumlxi' }

          it "sets all the options on the roundtripped Regexp::Raw object in order" do
            expect(roundtripped.options).to eq(options.chars.sort.join)
          end
        end
      end
    end
  end
end