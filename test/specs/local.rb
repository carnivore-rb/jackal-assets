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
    @tmp_dir_src, @tmp_dir_dst = Dir.mktmpdir, Dir.mktmpdir
    @files = ['file1', 'file2']
    @files.each { |f| FileUtils.cp(@file.path, "#{@tmp_dir_src}/#{f}") }
  end

  after do
    FileUtils.rm_rf([@tmp_dir_src, @tmp_dir_dst])
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

  it 'packs / unpacks directory contents' do
    archive = @store.pack(@tmp_dir_src)
    @store.unpack(archive, @tmp_dir_dst)
    unpacked_files = Dir["#{@tmp_dir_dst}/*"]
    unpacked_files.map{ |f| File.basename(f) }.must_equal(@files)
    unpacked_files.each do |f|
      File.read(f).must_equal(@content)
    end
  end
end
