require 'securerandom'
require 'jackal-assets'

describe Jackal::Assets::Store do

  before do
    require 'jackal-assets'
    @store = Jackal::Assets::Store.new(
      :bucket => 'jackal-assets-test',
      :connection => {
        :provider => :local,
        :credentials => {
          :object_store_root => '/tmp/jackal-test'
        }
      }
    )
    @content = 20.times.map{ SecureRandom.uuid }.join("\n")
    @file = Tempfile.new('jackal-asset-test')
    @file.write @content
    @file.rewind
    @key = SecureRandom.uuid
  end

  it 'creates new objects' do
    @store.put(@key, @file).must_equal true
  end

  it 'retrieves objects into tempfile' do
    @store.put(@key, @file).must_equal true
    result = @store.get(@key)
    result.is_a?(Tempfile)
    result.read.must_equal @content
  end

  it 'deletes objects' do
    @store.put(@key, @file).must_equal true
    result = @store.get(@key)
    result.is_a?(Tempfile)
    result.read.must_equal @content
    @store.delete(@key)
    proc{ @store.get(@key) }.must_raise Jackal::Assets::Error::NotFound
  end
end
