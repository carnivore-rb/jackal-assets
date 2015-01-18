# Jackal Assets

Simple API to store and retrieve objects.

## Usage

```ruby

require 'jackal-assets'

object_store = Jackal::Assets::Store.new
object = object_store.get('item/i/want.json')

File.open('/tmp/fubar', 'w') do |f|
  f.write object.readpartial
  f.puts 'YAY'
end

object_store.put('my/updated/file.json', '/tmp/fubar')
```

## Configuration

Configure

```json
{
  "jackal": {
    "assets": {
      "connection": {
        "provider": "aws",
        "credentials": {
        }
      },
      "bucket": "BUCKET_NAME"
    }
  }
}
```

# Info
* Repository: https://github.com/carnivore-rb/jackal-assets