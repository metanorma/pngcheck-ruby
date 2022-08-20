[![test-and-release](https://github.com/metanorma/pngcheck-ruby/actions/workflows/test-and-release.yml/badge.svg)](https://github.com/metanorma/pngcheck-ruby/actions/workflows/test-and-release.yml)

# PngCheck

pngcheck gem verifies the integrity of PNG, JNG and MNG files (by checking the internal 32-bit CRCs, a.k.a. checksums, and decompressing the image data); it can optionally dump almost all of the chunk-level information in the image in human-readable form. For example, it can be used to print the basic statistics about an image (dimensions, bit depth, etc.); to list the color and transparency info in its palette (assuming it has one); or to extract the embedded text annotations.

pngcheck is a Ruby wrapper around original pngcheck tool available at http://www.libpng.org/pub/png/apps/pngcheck.html

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pngcheck'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pngcheck

## Usage

### Png status codes

```ruby
PngCheck::STATUS_OK = 0
PngCheck::STATUS_WARNING = 1        # an error in some circumstances but not in all
PngCheck::STATUS_MINOR_ERROR = 3    # minor spec errors (e.g., out-of-range values)
PngCheck::STATUS_MAJOR_ERROR = 4    # file corruption, invalid chunk length/layout, etc.
PngCheck::STATUS_CRITICAL_ERROR = 5 # unexpected EOF or other file(system) error
```

### File processing

```ruby
status, info = PngCheck.analyze_file("spec/examples/correct.png")
```
where ```status``` is file status code and ```info``` is either file content information for correct files or error message for corrupt files

```ruby
valid = PngCheck.check_file("spec/examples/correct.png")
```
```valid = true``` if the file is correct otherwise an exception of type ```PngCheck::CorruptPngError``` is railed

### Memory buffer processing

```ruby
data = File.binread("spec/examples/correct.png")
status, info = PngCheck.analyze_buffer(data)
```
where ```status``` is file status code and ```info``` is either file content information for correct files or error message for corrupt files

```ruby
data = File.binread("spec/examples/correct.png")
valid = PngCheck.check_buffer(data)
```
```valid = true``` if the file is correct otherwise an exception of type ```PngCheck::CorruptPngError``` is railed

### Using with libpng-ruby
```ruby
require 'png'
encoded = File.binread("spec/examples/correct.png")
begin
    expect(PngCheck.check_buffer(encoded)).to eql true
    dec = PNG::Decoder.new
    raw = dec << encoded
rescue PngCheck::CorruptPngError => e
    puts "Exception #{e.message}"
end
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/metanorma/pngcheck-ruby.
