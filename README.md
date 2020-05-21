# Linux 4 Kids

Linux 4 Kids is a simplified desktop environment for kids. The project is based on the Awesome Window Manager.

## Installation

To install the kids desktop you first need to install the awesome wm and git:

### In Ubuntu:

`$ sudo apt update && sudo apt install awesome git`

### In Arch:

`$ sudo pacman -S awesome git`

### Create new user for the kid

To create a new user for the kid (replace <username> with an actual username):

`$ sudo useradd -m -G wheel <username>`

### Pull the kid repo

```
$ su <username>
$ cd
$ git init
$ git remote add origin https://github.com/br0uQ/linux4kids_kid.git
$ git pull origin master
```

### Create a xinitrc to load awesomewm

`$ nano .xinitrc`

The `.xinitrc` file should contain the following:

```
#!/bin/sh

# /etc/X11/xinit/xinitrc
#
# global xinitrc file, used by all X sessions started by xinit (startx)

# invoke global X session script
exec awesome
```

## Start Linux4Kids desktop

Switch to another tty: <Ctrl>+<Alt>+<F2>

Log into the kids account.

Start the Linux4Kids desktop:

`$ startx`
