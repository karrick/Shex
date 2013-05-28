## Shex

The Shex gem provides library functions to perform Shell Execution.
It has some facilities that make executing programs on other hosts and
as other UNIX users quite natural.

```ruby
require 'rubygems'
require 'Shex'

Shex.shex("find /root", :host => 'somewhere.example.com', :user => 'root')
```

If the host parameter is provided, and is not the string 'localhost',
and is not the actual name of your host as provided by `hostname -s`,
it will wrap your command with ssh.

If the user parameter is provided, and is not equivalent to your
process's LOGNAME environment variable, it will wrap your command with
sudo.


## INSTALLATION

To install this Ruby Gem, run the following commands:

```bash
rake test
rake install
```

Or run `rake -T` for more options.


## KNOWN LIMITATIONS

Does not work with JRuby.  I would like to make this work, but do not
know when I will find the time to make it happen.


## LICENSE AND COPYRIGHT

Copyright (C) 2012 Karrick S. McDermott

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://ruby-lang.org/en/LICENSE.txt for more information.
