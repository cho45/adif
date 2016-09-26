# ADIF

This is ADIF (Amateur Data Interchange Format) Parser/Writer library for Ruby.

ADIF is an open standard for exchange of data between ham radio software packages available from different vendors.

## Installation

This gem is not available via [rubygems.org](https://rubygems.org), but you can easily build it yourself:

    git clone https://github.com/cho45/adif.git
    cd adif
    gem build adif.gemspec
    gem install adif

To use it, add this line to your application's Gemfile:

    gem 'adif'

And then execute:

    $ bundle

## Usage

[./spec/adif_spec.rb](./spec/adif_spec.rb )

## Contributing

1. Fork it ( https://github.com/cho45/adif/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
